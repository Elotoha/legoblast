#!/usr/bin/env python3
"""Train a PPO policy offline against the C++ LegoBlast engine."""

import argparse
from contextlib import ExitStack
import json
import os
from pathlib import Path
import subprocess
import tempfile

# The matrices are small. Avoid a BLAS thread pool per training process.
os.environ.setdefault("OPENBLAS_NUM_THREADS", "1")
os.environ.setdefault("OMP_NUM_THREADS", "1")
import numpy as np

ACTIONS = 10


class Engine:
    def __init__(self, lab, opponent, levels):
        self.process = subprocess.Popen(
            [str(lab.resolve()), "serve", opponent, *map(str, levels)],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True,
            encoding="utf-8", bufsize=1,
        )

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.process.stdin.close()
        try:
            self.process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait()
        self.process.stdout.close()

    def request(self, line):
        self.process.stdin.write(line + "\n")
        self.process.stdin.flush()
        result = self.process.stdout.readline()
        if not result:
            raise RuntimeError("le simulateur a quitté sans répondre")
        return json.loads(result)


class Network:
    def __init__(self, features, hidden, rng, checkpoint):
        def weights(fan_in, fan_out, gain):
            shape = (fan_in, fan_out)
            return (rng.standard_normal(shape) * gain / np.sqrt(fan_in)).astype(np.float32)

        self.parameters = {
            "input": weights(features, hidden, 1.0),
            "hidden": np.zeros(hidden, dtype=np.float32),
            "policy": weights(hidden, ACTIONS, 0.01),
            "actions": np.zeros(ACTIONS, dtype=np.float32),
            "value": weights(hidden, 1, 1.0),
            "mean": np.zeros(1, dtype=np.float32),
        }
        self.first = {key: np.zeros_like(value) for key, value in self.parameters.items()}
        self.second = {key: np.zeros_like(value) for key, value in self.parameters.items()}
        self.updates = 0
        if checkpoint is not None:
            with np.load(checkpoint, allow_pickle=False) as data:
                for name, value in self.parameters.items():
                    loaded = data[name]
                    if loaded.shape != value.shape or not np.isfinite(loaded).all():
                        raise ValueError(f"dimensions ou poids invalides dans {checkpoint}: {name}")
                    value[:] = loaded
                    self.first[name][:] = data[f"first_{name}"]
                    self.second[name][:] = data[f"second_{name}"]
                self.updates = int(data["updates"])

    def forward(self, observations):
        p = self.parameters
        hidden = np.tanh(observations @ p["input"] + p["hidden"])
        logits = hidden @ p["policy"] + p["actions"]
        centered = logits - logits.max(axis=1, keepdims=True)
        log_prob = centered - np.log(np.exp(centered).sum(axis=1, keepdims=True))
        return hidden, log_prob, (hidden @ p["value"] + p["mean"])[:, 0]

    def update(self, obs, actions, old_log_prob, advantages, returns, rate):
        p = self.parameters
        hidden, log_prob, values = self.forward(obs)
        row = np.arange(len(actions))
        ratio = np.exp(log_prob[row, actions] - old_log_prob)
        active = np.where(advantages >= 0, ratio <= 1.2, ratio >= 0.8)
        probability = np.exp(log_prob)
        selected = -probability.copy()
        selected[row, actions] += 1
        entropy_gradient = probability * (log_prob - (probability * log_prob).sum(axis=1, keepdims=True))
        policy_delta = (selected * (-advantages * ratio * active)[:, None] +
                        0.01 * entropy_gradient) / len(obs)
        value_delta = (0.5 * (values - returns) / len(obs))[:, None]
        hidden_delta = (policy_delta @ p["policy"].T + value_delta @ p["value"].T) * (1 - hidden ** 2)
        gradients = {
            "input": obs.T @ hidden_delta,
            "hidden": hidden_delta.sum(axis=0),
            "policy": hidden.T @ policy_delta,
            "actions": policy_delta.sum(axis=0),
            "value": hidden.T @ value_delta,
            "mean": value_delta.sum(axis=0),
        }
        norm = np.sqrt(sum(float(np.square(g).sum()) for g in gradients.values()))
        self.updates += 1
        for name, gradient in gradients.items():
            gradient *= min(1., 0.5 / max(norm, 1e-8))
            first, second = self.first[name], self.second[name]
            first[:] = 0.9 * first + 0.1 * gradient
            second[:] = 0.999 * second + 0.001 * gradient ** 2
            corrected_mean = first / (1 - 0.9 ** self.updates)
            corrected_square = second / (1 - 0.999 ** self.updates)
            p[name] -= rate * corrected_mean / (np.sqrt(corrected_square) + 1e-8)

    def save(self, destination):
        p = self.parameters
        for value in p.values():
            if not np.isfinite(value).all():
                raise RuntimeError("poids non finis")
        destination.parent.mkdir(parents=True, exist_ok=True)
        features, hidden = p["input"].shape
        with tempfile.NamedTemporaryFile(dir=destination.parent, mode="w", encoding="ascii",
                                         delete=False) as temporary:
            temporary.write(f"LIA1 {features} {hidden} {ACTIONS}\n")
            for weights in [p["input"].T, p["hidden"], p["policy"].T, p["actions"]]:
                np.savetxt(temporary, weights.reshape(1, -1), fmt="%.9g")
        os.replace(temporary.name, destination)
        checkpoint = destination.with_suffix(destination.suffix + ".npz")
        with tempfile.NamedTemporaryFile(dir=destination.parent, mode="wb", delete=False) as temporary:
            np.savez(temporary, **p, updates=self.updates,
                     **{f"first_{name}": value for name, value in self.first.items()},
                     **{f"second_{name}": value for name, value in self.second.items()})
        os.replace(temporary.name, checkpoint)


def train(args):
    rng = np.random.default_rng(args.seed)
    with ExitStack() as stack:
        engines = [stack.enter_context(Engine(args.lab, args.opponent, args.levels))
                   for _ in range(args.envs)]

        def reset(engine):
            arena = rng.integers(len(args.levels))
            seat = rng.integers(2)
            seed = rng.integers(2 ** 32, dtype=np.uint32)
            return engine.request(f"R {arena} {seat} {seed} {args.max_ticks}")["observation"]

        obs = np.asarray([reset(engine) for engine in engines], dtype=np.float32)
        network = Network(obs.shape[1], args.hidden, rng, args.resume)
        row = np.arange(args.envs)
        for iteration in range(1, args.iterations + 1):
            observations, actions, logs, values = [], [], [], []
            rewards, next_values, unfinished = [], [], []
            wins = losses = draws = truncated = 0
            for _ in range(args.rollout):
                _, log_prob, value = network.forward(obs)
                sampled = np.array([rng.choice(ACTIONS, p=np.exp(log).astype(np.float64) /
                                               np.exp(log).astype(np.float64).sum())
                                    for log in log_prob])
                steps = [engine.request(f"S {action}") for engine, action in zip(engines, sampled)]
                after = np.asarray([step["observation"] for step in steps], dtype=np.float32)
                terminated = np.asarray([bool(step["terminated"]) for step in steps])
                limits = np.asarray([bool(step["truncated"]) for step in steps])
                done = terminated | limits

                observations.append(obs)
                actions.append(sampled)
                logs.append(log_prob[row, sampled])
                values.append(value)
                rewards.append(np.asarray([step["reward"] for step in steps], dtype=np.float32))
                next_values.append(network.forward(after)[2] * ~terminated)
                unfinished.append(~done)
                wins += sum(step["outcome"] > 0 for step in steps)
                losses += sum(step["outcome"] < 0 for step in steps)
                draws += sum(step["terminated"] and not step["outcome"] for step in steps)
                truncated += int(limits.sum())
                obs = after
                for i in np.flatnonzero(done):
                    obs[i] = reset(engines[i])

            advantages = np.zeros_like(rewards)
            estimate = np.zeros(args.envs, dtype=np.float32)
            for i in reversed(range(args.rollout)):
                delta = rewards[i] + 0.995 * next_values[i] - values[i]
                estimate = delta + 0.995 * 0.95 * unfinished[i] * estimate
                advantages[i] = estimate
            returns = (np.asarray(values) + advantages).ravel()
            advantages = advantages.ravel()
            advantages = (advantages - advantages.mean()) / (advantages.std() + 1e-8)
            observations = np.concatenate(observations)
            actions, logs = np.concatenate(actions), np.concatenate(logs)
            for _ in range(args.epochs):
                order = rng.permutation(len(actions))
                for start in range(0, len(order), args.batch):
                    batch = order[start:start + args.batch]
                    network.update(observations[batch], actions[batch], logs[batch],
                                   advantages[batch], returns[batch], args.rate)
            network.save(args.output)
            print(json.dumps(dict(iteration=iteration, transitions=iteration * len(actions), wins=int(wins),
                                  losses=int(losses), draws=int(draws), truncated=truncated,
                                  mean_reward=float(np.mean(rewards)))), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lab", required=True, type=Path)
    parser.add_argument("--levels", required=True, type=Path, nargs="+")
    parser.add_argument("--opponent", default="micro")
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--resume", type=Path)
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--hidden", type=int, default=64)
    parser.add_argument("--envs", type=int, default=4)
    parser.add_argument("--iterations", type=int, default=50)
    parser.add_argument("--rollout", type=int, default=128)
    parser.add_argument("--batch", type=int, default=128)
    parser.add_argument("--epochs", type=int, default=4)
    parser.add_argument("--max-ticks", type=int, default=5000)
    parser.add_argument("--rate", type=float, default=3e-4)
    args = parser.parse_args()
    if not (0 < args.hidden <= 512 and args.seed >= 0 and 0 < args.rate <= 1 and
            min(args.envs, args.iterations, args.rollout, args.batch, args.epochs, args.max_ticks) > 0):
        parser.error("paramètres d’entraînement hors limites")
    train(args)


if __name__ == "__main__":
    main()
