import CWebP

enum WebPLibrary {
    static var encoderVersion: Int32 { Int32(WebPGetEncoderVersion()) }
}
