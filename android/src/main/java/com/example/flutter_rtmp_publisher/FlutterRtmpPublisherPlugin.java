package com.example.flutter_rtmp_publisher;

import android.util.Log;
import java.util.List;
import java.util.ArrayList;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class FlutterRtmpPublisherPlugin implements FlutterPlugin, MethodCallHandler {
    static List<RTMPCamera> cameraList = new ArrayList<>();
    private MethodChannel channel;

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        RTMPCamera.setBinaryMessenger(binding.getBinaryMessenger());
        binding.getPlatformViewRegistry().registerViewFactory("flutter_rtmp_publisher/RTMPCameraPreview", new RTMPCameraPreviewFactory(binding.getBinaryMessenger()));
        channel = new MethodChannel(binding.getBinaryMessenger(), "flutter_rtmp_publisher/method");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "NewRTMPCamera": {
                Integer id = cameraList.size();
                cameraList.add(new RTMPCamera(id));
                result.success(id);
                break;
            }
            case "DisposeRTMPCamera": {
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;
            }
            default: {
                Log.i("RTMP Publisher Plugin", "Method call error: " + call.method);
                result.notImplemented();
                break;
            }
        }
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }
}
