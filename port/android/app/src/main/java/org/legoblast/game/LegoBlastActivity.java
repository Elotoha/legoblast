package org.legoblast.game;

import android.content.res.AssetManager;
import android.util.Log;
import android.widget.Toast;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;

import org.libsdl.app.SDLActivity;

public final class LegoBlastActivity extends SDLActivity {
    @Override
    protected String[] getLibraries() {
        return new String[] { "SDL3", "legoblast_players" };
    }

    @Override
    protected void main() {
        // SDL calls this on the game thread. The UI can handle lifecycle events
        // while the original assets are copied out of the APK on first launch.
        try {
            installAssets();
        } catch (IOException error) {
            Log.e("LegoBlast", "Could not install game data", error);
            runOnUiThread(() -> Toast.makeText(this,
                "LegoBlast: unable to prepare the game data", Toast.LENGTH_LONG).show());
            return;
        }
        super.main();
    }

    public GameSocket openGameSocket(String address) {
        GameSocket socket = new GameSocket(address);
        socket.connect();
        return socket;
    }

    private void installAssets() throws IOException {
        byte[] id;
        try (InputStream bundledId = getAssets().open("data.id")) {
            // The manifest is one short ASCII line, compatible with Android 8.
            id = new byte[65];
            int offset = 0;
            while (offset < id.length) {
                int count = bundledId.read(id, offset, id.length - offset);
                if (count < 0)
                    throw new IOException("Truncated asset manifest");
                offset += count;
            }
        }
        String version = new String(id, StandardCharsets.US_ASCII).trim();
        File data = new File(getFilesDir(), "data");
        File marker = new File(data, ".id");
        if (marker.isFile() && version.equals(new String(
                Files.readAllBytes(marker.toPath()), StandardCharsets.US_ASCII).trim()))
            return;

        File staging = new File(getFilesDir(), "data.staging");
        removeTree(staging);
        copyAssets("data", staging);
        Files.write(new File(staging, ".id").toPath(), id);
        removeTree(data);
        Files.move(staging.toPath(), data.toPath());
    }

    private void copyAssets(String path, File destination) throws IOException {
        AssetManager assets = getAssets();
        String[] entries = assets.list(path);
        if (entries != null && entries.length > 0) {
            if (!destination.mkdir())
                throw new IOException("Could not create " + destination);
            for (String entry : entries)
                copyAssets(path + "/" + entry, new File(destination, entry));
            return;
        }
        try (InputStream input = assets.open(path); FileOutputStream output = new FileOutputStream(destination)) {
            byte[] buffer = new byte[65536];
            for (int count; (count = input.read(buffer)) != -1;)
                output.write(buffer, 0, count);
        }
    }

    private static void removeTree(File file) throws IOException {
        File[] entries = file.listFiles();
        if (entries != null)
            for (File entry : entries)
                removeTree(entry);
        Files.deleteIfExists(file.toPath());
    }
}
