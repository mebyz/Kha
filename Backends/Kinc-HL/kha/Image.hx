package kha;

import haxe.io.Bytes;
import haxe.io.BytesData;
import kha.korehl.graphics4.TextureUnit;
import kha.graphics4.TextureFormat;
import kha.graphics4.DepthStencilFormat;
import kha.graphics4.Usage;

class Image implements Canvas implements Resource {
	public var _texture: Pointer;
	public var _renderTarget: Pointer;
	public var _textureArray: Pointer;
	public var _textureArrayTextures: Pointer;

	var myFormat: TextureFormat;
	var readable: Bool;

	var graphics1: kha.graphics1.Graphics;
	var graphics2: kha.graphics2.Graphics;
	var graphics4: kha.graphics4.Graphics;

	public static function fromVideo(video: Video): Image {
		var image = new Image(false);
		image.myFormat = TextureFormat.RGBA32;
		image.initVideo(cast(video, kha.korehl.Video));
		return image;
	}

	public static function create(width: Int, height: Int, format: TextureFormat = null, usage: Usage = null, readable: Bool = false): Image {
		return create2(width, height, format == null ? TextureFormat.RGBA32 : format, readable, false, NoDepthAndStencil);
	}

	public static function create3D(width: Int, height: Int, depth: Int, format: TextureFormat = null, usage: Usage = null, readable: Bool = false): Image {
		return create3(width, height, depth, format == null ? TextureFormat.RGBA32 : format, readable, 0);
	}

	public static function createRenderTarget(width: Int, height: Int, format: TextureFormat = null, depthStencil: DepthStencilFormat = NoDepthAndStencil,
			antiAliasingSamples: Int = 1): Image {
		return create2(width, height, format == null ? TextureFormat.RGBA32 : format, false, true, depthStencil);
	}

	// public static function createArray(images: Array<Image>, format: TextureFormat = null): Image {
	// var image = new Image(false);
	// image.myFormat = (format == null) ? TextureFormat.RGBA32 : format;
	// initArrayTexture(image, images);
	// return image;
	// }

	public static function fromBytes(bytes: Bytes, width: Int, height: Int, format: TextureFormat = null, usage: Usage = null, readable: Bool = false): Image {
		var image = new Image(readable);
		image.myFormat = format;
		image.initFromBytes(bytes.getData(), width, height, getTextureFormat(format));
		return image;
	}

	function initFromBytes(bytes: BytesData, width: Int, height: Int, format: Int): Void {
		_texture = kinc_texture_from_bytes(bytes.bytes, width, height, format, readable);
	}

	public static function fromBytes3D(bytes: Bytes, width: Int, height: Int, depth: Int, format: TextureFormat = null, usage: Usage = null, readable: Bool = false): Image {
		var image = new Image(readable);
		image.myFormat = format;
		image.initFromBytes3D(bytes.getData(), width, height, depth, getTextureFormat(format));
		return image;
	}

	function initFromBytes3D(bytes: BytesData, width: Int, height: Int, depth: Int, format: Int): Void {
		_texture = kinc_texture_from_bytes3d(bytes.bytes, width, height, depth, format, readable);
	}

	public static function fromEncodedBytes(bytes: Bytes, format: String, doneCallback: Image->Void, errorCallback: String->Void,
			readable: Bool = false): Void {
		var image = new Image(readable);
		var isFloat = format == "hdr" || format == "HDR";
		image.myFormat = isFloat ? TextureFormat.RGBA128 : TextureFormat.RGBA32;
		image.initFromEncodedBytes(bytes.getData(), format);
		doneCallback(image);
	}

	function initFromEncodedBytes(bytes: BytesData, format: String): Void {
		_texture = kinc_texture_from_encoded_bytes(bytes.bytes, bytes.length, StringHelper.convert(format), readable);
	}

	function new(readable: Bool) {
		this.readable = readable;
	}

	static function getRenderTargetFormat(format: TextureFormat): Int {
		switch (format) {
			case RGBA32: // Target32Bit
				return 0;
			case RGBA64: // Target64BitFloat
				return 1;
			case RGBA128: // Target128BitFloat
				return 3;
			case DEPTH16: // Target16BitDepth
				return 4;
			default:
				return 0;
		}
	}

	static function getDepthBufferBits(depthAndStencil: DepthStencilFormat): Int {
		return switch (depthAndStencil) {
			case NoDepthAndStencil: -1;
			case DepthOnly: 24;
			case DepthAutoStencilAuto: 24;
			case Depth24Stencil8: 24;
			case Depth32Stencil8: 32;
			case Depth16: 16;
		}
	}

	static function getStencilBufferBits(depthAndStencil: DepthStencilFormat): Int {
		return switch (depthAndStencil) {
			case NoDepthAndStencil: -1;
			case DepthOnly: -1;
			case DepthAutoStencilAuto: 8;
			case Depth24Stencil8: 8;
			case Depth32Stencil8: 8;
			case Depth16: 0;
		}
	}

	static function getTextureFormat(format: TextureFormat): Int {
		switch (format) {
			case RGBA32:
				return 0;
			case RGBA128:
				return 3;
			case RGBA64:
				return 4;
			case A32:
				return 5;
			case A16:
				return 7;
			default:
				return 1; // Grey8
		}
	}

	public static function create2(width: Int, height: Int, format: TextureFormat, readable: Bool, renderTarget: Bool, depthStencil: DepthStencilFormat): Image {
		var image = new Image(readable);
		image.myFormat = format;
		if (renderTarget)
			image.initRenderTarget(width, height, getDepthBufferBits(depthStencil), getRenderTargetFormat(format), getStencilBufferBits(depthStencil));
		else
			image.init(width, height, format);
		return image;
	}

	public static function create3(width: Int, height: Int, depth: Int, format: TextureFormat, readable: Bool, contextId: Int): Image {
		var image = new Image(readable);
		image.myFormat = format;
		image.init3D(width, height, depth, getTextureFormat(format));
		return image;
	}

	function initRenderTarget(width: Int, height: Int, depthBufferBits: Int, format: Int, stencilBufferBits: Int): Void {
		_renderTarget = kinc_render_target_create(width, height, depthBufferBits, format, stencilBufferBits);
		_texture = null;
	}

	function init(width: Int, height: Int, format: Int): Void {
		_texture = kinc_texture_create(width, height, format, readable);
		_renderTarget = null;
	}

	function init3D(width: Int, height: Int, depth: Int, format: Int): Void {
		_texture = kinc_texture_create3d(width, height, depth, format, readable);
		_renderTarget = null;
	}

	function initVideo(video: kha.korehl.Video): Void {
		_texture = kinc_video_get_current_image(video._video);
		_renderTarget = null;
	}

	public static function fromFile(filename: String, readable: Bool): Image {
		var image = new Image(readable);
		var isFloat = StringTools.endsWith(filename, ".hdr");
		image.myFormat = isFloat ? TextureFormat.RGBA128 : TextureFormat.RGBA32;
		image.initFromFile(filename);
		if (image._texture == null) {
			return null;
		}
		return image;
	}

	function initFromFile(filename: String): Void {
		_texture = kinc_texture_create_from_file(StringHelper.convert(filename), readable);
		_renderTarget = null;
	}

	public var g1(get, never): kha.graphics1.Graphics;

	function get_g1(): kha.graphics1.Graphics {
		if (graphics1 == null) {
			graphics1 = new kha.graphics2.Graphics1(this);
		}
		return graphics1;
	}

	public var g2(get, never): kha.graphics2.Graphics;

	function get_g2(): kha.graphics2.Graphics {
		if (graphics2 == null) {
			graphics2 = new kha.korehl.graphics4.Graphics2(this);
		}
		return graphics2;
	}

	public var g4(get, never): kha.graphics4.Graphics;

	function get_g4(): kha.graphics4.Graphics {
		if (graphics4 == null) {
			graphics4 = new kha.korehl.graphics4.Graphics(this);
		}
		return graphics4;
	}

	public static var maxSize(get, never): Int;

	static function get_maxSize(): Int {
		return 4096;
	}

	public static var nonPow2Supported(get, never): Bool;

	static function get_nonPow2Supported(): Bool {
		return kinc_non_pow2_textures_supported();
	}

	public static function renderTargetsInvertedY(): Bool {
		return kinc_graphics_render_targets_inverted_y();
	}

	public var width(get, never): Int;

	function get_width(): Int {
		return _texture != null ? kinc_texture_get_width(_texture) : kinc_render_target_get_width(_renderTarget);
	}

	public var height(get, never): Int;

	function get_height(): Int {
		return _texture != null ? kinc_texture_get_height(_texture) : kinc_render_target_get_height(_renderTarget);
	}

	public var depth(get, never): Int;

	function get_depth(): Int {
		return 1;
	}

	public var format(get, never): TextureFormat;

	function get_format(): TextureFormat {
		return myFormat;
	}

	public var realWidth(get, never): Int;

	function get_realWidth(): Int {
		return _texture != null ? kinc_texture_get_real_width(_texture) : kinc_render_target_get_real_width(_renderTarget);
	}

	public var realHeight(get, never): Int;

	function get_realHeight(): Int {
		return _texture != null ? kinc_texture_get_real_height(_texture) : kinc_render_target_get_real_height(_renderTarget);
	}

	public var stride(get, never): Int;

	function get_stride(): Int {
		return formatByteSize(myFormat) * width;
	}

	public function isOpaque(x: Int, y: Int): Bool {
		return atInternal(x, y) & 0xff != 0;
	}

	function atInternal(x: Int, y: Int): Int {
		return kinc_texture_at(_texture, x, y);
	}

	public inline function at(x: Int, y: Int): Color {
		return Color.fromValue(atInternal(x, y));
	}

	public function unload(): Void {
		_texture != null ? kinc_texture_unload(_texture) : kinc_render_target_unload(_renderTarget);
	}

	var bytes: Bytes = null;

	public function lock(level: Int = 0): Bytes {
		bytes = Bytes.alloc(formatByteSize(myFormat) * width * height);
		return bytes;
	}

	public function unlock(): Void {
		kinc_texture_unlock(_texture, bytes.getData().bytes);
		bytes = null;
	}

	var pixels: Bytes = null;

	public function getPixels(): Bytes {
		if (_renderTarget == null)
			return null;
		if (pixels == null) {
			var size = formatByteSize(myFormat) * width * height;
			pixels = Bytes.alloc(size);
		}
		kinc_render_target_get_pixels(_renderTarget, pixels.getData().bytes);
		return pixels;
	}

	static function formatByteSize(format: TextureFormat): Int {
		return switch (format) {
			case RGBA32: 4;
			case L8: 1;
			case RGBA128: 16;
			case DEPTH16: 2;
			case RGBA64: 8;
			case A32: 4;
			case A16: 2;
			default: 4;
		}
	}

	public function generateMipmaps(levels: Int): Void {
		_texture != null ? kinc_generate_mipmaps_texture(_texture, levels) : kinc_generate_mipmaps_target(_renderTarget, levels);
	}

	public function setMipmaps(mipmaps: Array<Image>): Void {
		for (i in 0...mipmaps.length) {
			var image = mipmaps[i];
			var level = i + 1;
			kinc_set_mipmap_texture(_texture, image._texture, level);
		}
	}

	public function setDepthStencilFrom(image: Image): Void {
		kinc_render_target_set_depth_stencil_from(_renderTarget, image._renderTarget);
	}

	public function clear(x: Int, y: Int, z: Int, width: Int, height: Int, depth: Int, color: Color): Void {
		kinc_texture_clear(_texture, x, y, z, width, height, depth, color);
	}

	@:hlNative("std", "kinc_texture_create") static function kinc_texture_create(width: Int, height: Int, format: Int, readable: Bool): Pointer {
		return null;
	}

	@:hlNative("std", "kinc_texture_create_from_file") static function kinc_texture_create_from_file(filename: hl.Bytes, readable: Bool): Pointer {
		return null;
	}

	@:hlNative("std", "kinc_texture_create3d") static function kinc_texture_create3d(width: Int, height: Int, depth: Int, format: Int,
			readable: Bool): Pointer {
		return null;
	}

	@:hlNative("std", "kinc_video_get_current_image") static function kinc_video_get_current_image(video: Pointer): Pointer {
		return null;
	}

	@:hlNative("std", "kinc_texture_from_bytes") static function kinc_texture_from_bytes(bytes: Pointer, width: Int, height: Int, format: Int,
			readable: Bool): Pointer {
		return null;
	}

	@:hlNative("std", "kinc_texture_from_bytes3d") static function kinc_texture_from_bytes3d(bytes: Pointer, width: Int, height: Int, depth: Int, format: Int,
			readable: Bool): Pointer {
		return null;
	}

	@:hlNative("std", "kinc_texture_from_encoded_bytes") static function kinc_texture_from_encoded_bytes(bytes: Pointer, length: Int, format: hl.Bytes,
			readable: Bool): Pointer {
		return null;
	}

	@:hlNative("std", "kinc_non_pow2_textures_supported") static function kinc_non_pow2_textures_supported(): Bool {
		return false;
	}

	@:hlNative("std", "kinc_graphics_render_targets_inverted_y") static function kinc_graphics_render_targets_inverted_y(): Bool {
		return false;
	}

	@:hlNative("std", "kinc_texture_get_width") static function kinc_texture_get_width(texture: Pointer): Int {
		return 0;
	}

	@:hlNative("std", "kinc_texture_get_height") static function kinc_texture_get_height(texture: Pointer): Int {
		return 0;
	}

	@:hlNative("std", "kinc_texture_get_real_width") static function kinc_texture_get_real_width(texture: Pointer): Int {
		return 0;
	}

	@:hlNative("std", "kinc_texture_get_real_height") static function kinc_texture_get_real_height(texture: Pointer): Int {
		return 0;
	}

	@:hlNative("std", "kinc_texture_at") static function kinc_texture_at(texture: Pointer, x: Int, y: Int): Int {
		return 0;
	}

	@:hlNative("std", "kinc_texture_unload") static function kinc_texture_unload(texture: Pointer): Void {}

	@:hlNative("std", "kinc_render_target_unload") static function kinc_render_target_unload(renderTarget: Pointer): Void {}

	@:hlNative("std", "kinc_render_target_create") static function kinc_render_target_create(width: Int, height: Int, depthBufferBits: Int, format: Int,
			stencilBufferBits: Int): Pointer {
		return null;
	}

	@:hlNative("std", "kinc_render_target_get_width") static function kinc_render_target_get_width(renderTarget: Pointer): Int {
		return 0;
	}

	@:hlNative("std", "kinc_render_target_get_height") static function kinc_render_target_get_height(renderTarget: Pointer): Int {
		return 0;
	}

	@:hlNative("std", "kinc_render_target_get_real_width") static function kinc_render_target_get_real_width(renderTarget: Pointer): Int {
		return 0;
	}

	@:hlNative("std", "kinc_render_target_get_real_height") static function kinc_render_target_get_real_height(renderTarget: Pointer): Int {
		return 0;
	}

	@:hlNative("std", "kinc_texture_unlock") static function kinc_texture_unlock(texture: Pointer, bytes: Pointer): Void {}

	@:hlNative("std", "kinc_render_target_get_pixels") static function kinc_render_target_get_pixels(renderTarget: Pointer, pixels: Pointer): Void {}

	@:hlNative("std", "kinc_generate_mipmaps_texture") static function kinc_generate_mipmaps_texture(texture: Pointer, levels: Int): Void {}

	@:hlNative("std", "kinc_generate_mipmaps_target") static function kinc_generate_mipmaps_target(renderTarget: Pointer, levels: Int): Void {}

	@:hlNative("std", "kinc_set_mipmap_texture") static function kinc_set_mipmap_texture(texture: Pointer, mipmap: Pointer, level: Int): Void {}

	@:hlNative("std", "kinc_render_target_set_depth_stencil_from") static function kinc_render_target_set_depth_stencil_from(renderTarget: Pointer,
			from: Pointer): Int {
		return 0;
	}

	@:hlNative("std", "kinc_texture_clear") static function kinc_texture_clear(texture: Pointer, x: Int, y: Int, z: Int, width: Int, height: Int, depth: Int,
		color: Color): Void {}
}
