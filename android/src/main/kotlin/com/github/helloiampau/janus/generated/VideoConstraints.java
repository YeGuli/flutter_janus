// AUTOGENERATED FILE - DO NOT MODIFY!
// This file generated by Djinni from janus-client.djinni

package com.github.helloiampau.janus.generated;

public final class VideoConstraints {


    /*package*/ final int width;

    /*package*/ final int height;

    /*package*/ final int fps;

    /*package*/ final String camera;

    public VideoConstraints(
            int width,
            int height,
            int fps,
            String camera) {
        this.width = width;
        this.height = height;
        this.fps = fps;
        this.camera = camera;
    }

    public int getWidth() {
        return width;
    }

    public int getHeight() {
        return height;
    }

    public int getFps() {
        return fps;
    }

    public String getCamera() {
        return camera;
    }

    @Override
    public String toString() {
        return "VideoConstraints{" +
                "width=" + width +
                "," + "height=" + height +
                "," + "fps=" + fps +
                "," + "camera=" + camera +
                "}";
    }

}
