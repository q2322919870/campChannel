import java.io.*;
import java.net.*;
import java.nio.channels.*;
import java.nio.file.*;

public class MavenWrapperDownloader {

    private static final String WRAPPER_VERSION = "3.3.2";

    private static final boolean VERBOSE = Boolean.parseBoolean(System.getenv("MVNW_VERBOSE"));

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("Usage: MavenWrapperDownloader <destination> <url>");
            System.exit(1);
        }

        Path destination = Paths.get(args[0]);
        String url = args[1];

        if (VERBOSE) {
            System.out.println("Downloading Maven Wrapper from: " + url);
            System.out.println("Destination: " + destination);
        }

        try {
            Files.createDirectories(destination.getParent());
            URL website = new URL(url);
            try (ReadableByteChannel rbc = Channels.newChannel(website.openStream());
                 FileOutputStream fos = new FileOutputStream(destination.toFile())) {
                fos.getChannel().transferFrom(rbc, 0, Long.MAX_VALUE);
            }
            if (VERBOSE) {
                System.out.println("Download complete.");
            }
        } catch (Exception e) {
            System.err.println("Error downloading Maven Wrapper: " + e.getMessage());
            Files.deleteIfExists(destination);
            throw e;
        }
    }
}
