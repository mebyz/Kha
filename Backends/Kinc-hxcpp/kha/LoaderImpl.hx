package kha;

import kha.arrays.Float32Array;
import haxe.io.Bytes;
import haxe.io.BytesData;

@:headerCode("
#include <kinc/input/keyboard.h>
#include <kinc/system.h>
#include <kinc/video.h>
#include <khalib/loader.h>
")
class BlobCallback {
	public var success: Blob->Void;
	public var error: AssetError->Void;

	public function new(success: Blob->Void, error: AssetError->Void) {
		this.success = success;
		this.error = error;
	}
}

class ImageCallback {
	public var success: Image->Void;
	public var error: AssetError->Void;

	public function new(success: Image->Void, error: AssetError->Void) {
		this.success = success;
		this.error = error;
	}
}

class SoundCallback {
	public var success: Sound->Void;
	public var error: AssetError->Void;

	public function new(success: Sound->Void, error: AssetError->Void) {
		this.success = success;
		this.error = error;
	}
}

class LoaderImpl {
	static var blobCallbacks = new Map<cpp.UInt64, BlobCallback>();
	static var imageCallbacks = new Map<cpp.UInt64, ImageCallback>();
	static var soundCallbacks = new Map<cpp.UInt64, SoundCallback>();

	public static function loadSoundFromDescription(desc: Dynamic, done: kha.Sound->Void, failed: AssetError->Void) {
		soundCallbacks[loadSound(desc.files[0])] = new SoundCallback(done, failed);
	}

	@:functionCode("return kha_loader_load_sound(filename);")
	static function loadSound(filename: String): cpp.UInt64 {
		return 0;
	}

	public static function getSoundFormats(): Array<String> {
		return ["wav", "ogg"];
	}

	public static function loadImageFromDescription(desc: Dynamic, done: kha.Image->Void, failed: AssetError->Void) {
		var readable = Reflect.hasField(desc, "readable") ? desc.readable : false;
		// done(kha.Image.fromFile(desc.files[0], readable));
		imageCallbacks[loadImage(desc.files[0], readable)] = new ImageCallback(done, failed);
	}

	@:functionCode("return kha_loader_load_image(filename, readable);")
	static function loadImage(filename: String, readable: Bool): cpp.UInt64 {
		return 0;
	}

	public static function getImageFormats(): Array<String> {
		return ["png", "jpg", "hdr"];
	}

	public static function loadBlobFromDescription(desc: Dynamic, done: Blob->Void, failed: AssetError->Void) {
		blobCallbacks[loadBlob(desc.files[0])] = new BlobCallback(done, failed);
	}

	@:functionCode("return kha_loader_load_blob(filename);")
	static function loadBlob(filename: String): cpp.UInt64 {
		return 0;
	}

	public static function loadFontFromDescription(desc: Dynamic, done: Font->Void, failed: AssetError->Void): Void {
		loadBlobFromDescription(desc, function(blob: Blob) {
			done(new Kravur(blob));
		}, failed);
	}

	public static function loadVideoFromDescription(desc: Dynamic, done: Video->Void, failed: AssetError->Void) {
		done(new kha.kore.Video(desc.files[0]));
	}

	@:functionCode("return ::String(kinc_video_formats()[0]);")
	static function videoFormat(): String {
		return "";
	}

	public static function getVideoFormats(): Array<String> {
		return [videoFormat()];
	}

	@:functionCode("kinc_keyboard_show();")
	public static function showKeyboard(): Void {}

	@:functionCode("kinc_keyboard_hide();")
	public static function hideKeyboard(): Void {}

	@:functionCode("kinc_load_url(url);")
	public static function loadURL(url: String): Void {}

	@:keep static function blobLoaded(index: cpp.UInt64, bytes: BytesData) {
		blobCallbacks[index].success(new Blob(Bytes.ofData(bytes)));
	}

	@:keep static function blobErrored(index: cpp.UInt64, filename: String) {
		blobCallbacks[index].error({url: filename});
	}

	@:keep static function soundLoadedCompressed(index: cpp.UInt64, bytes: BytesData) {
		var sound = new Sound();
		sound.compressedData = Bytes.ofData(bytes);
		sound.uncompressedData = null;
		sound.channels = 0;
		sound.sampleRate = 0;
		sound.length = 0;
		soundCallbacks[index].success(sound);
	}

	@:keep static function soundLoadedUncompressed(index: cpp.UInt64, samples: Float32Array, channels: Int, sampleRate: Int, length: Float) {
		var sound = new Sound();
		sound.compressedData = null;
		sound.uncompressedData = samples;
		sound.channels = channels;
		sound.sampleRate = sampleRate;
		sound.length = length;
		soundCallbacks[index].success(sound);
	}

	@:keep static function soundErrored(index: cpp.UInt64, filename: String) {
		soundCallbacks[index].error({url: filename});
	}

	@:keep static function createFloat32Array() {
		return new Float32Array(0);
	}

	@:keep static function createEmptyImage(readable: Bool, floatFormat: Bool) {
		return Image.createEmpty(readable, floatFormat);
	}

	@:keep static function imageLoaded(index: cpp.UInt64, image: Image) {
		imageCallbacks[index].success(image);
	}

	@:keep static function imageErrored(index: cpp.UInt64, filename: String) {
		imageCallbacks[index].error({url: filename});
	}

	@:functionCode("
		kha_file_reference_t file = kha_loader_get_file();
		while (file.index != 0) {
			switch (file.type) {
				case KHA_FILE_TYPE_BLOB:
					if (file.error) {
						blobErrored(file.index, file.name);
					}
					else {
						Array<unsigned char> buffer = Array_obj<unsigned char>::fromData(file.data.blob.bytes, file.data.blob.size);
						blobLoaded(file.index, buffer);
						kha_loader_cleanup_blob(file.data.blob);
					}
					break;
				case KHA_FILE_TYPE_IMAGE:
					if (file.error) {
						imageErrored(file.index, file.name);
					}
					else {
						::kha::Image image = createEmptyImage(file.data.image.readable, file.data.image.image.format == KINC_IMAGE_FORMAT_RGBA128);
						kinc_image_t kincImage;
						kinc_image_init(&kincImage, file.data.image.image.data, file.data.image.image.width, file.data.image.image.height, (kinc_image_format_t)file.data.image.image.format);
						kinc_g4_texture_init_from_image(&image->texture, &kincImage);
						if (file.data.image.readable) {
							image->imageData = (uint8_t*)kincImage.data;
						}
						else {
							free(file.data.image.image.data);
						}
						kinc_image_destroy(&kincImage);
						image->imageType = KhaImageTypeTexture;
						image->originalWidth = file.data.image.image.width;
						image->originalHeight = file.data.image.image.height;
						imageLoaded(file.index, image);
					}
					break;
				case KHA_FILE_TYPE_SOUND:
					if (file.error) {
						soundErrored(file.index, file.name);
					}
					else if (file.data.sound.samples != NULL) {
						::kha::arrays::ByteArrayPrivate buffer = createFloat32Array();
						buffer->self.data = (uint8_t*)file.data.sound.samples;
						buffer->byteArrayLength = file.data.sound.size * 4;
						buffer->byteArrayOffset = 0;
						soundLoadedUncompressed(file.index, buffer, file.data.sound.channels, file.data.sound.sample_rate, file.data.sound.length);
					}
					else {
						Array<unsigned char> buffer = Array_obj<unsigned char>::fromData(file.data.sound.compressed_samples, file.data.sound.size);
						soundLoadedCompressed(file.index, buffer);
						kha_loader_cleanup_sound(file.data.sound);
					}
					break;
			}

			file = kha_loader_get_file();
		}
	")
	public static function tick(): Void {}
}
