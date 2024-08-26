import std::io;
import raylib;
import qoi;

const int[<2>] WINDOW_SIZE = {800, 600};

fn int main(String[] args)
{
	raylib::init_window(WINDOW_SIZE.x, WINDOW_SIZE.y, "Hello, World!");
	defer raylib::close_window();

	// load a QOI image
	Desc dice;
	String path = "resources/dice.qoi";
	char[]! input_data = qoi::read(path, &dice, Channels.RGBA);
	if (catch f = input_data) {
		io::print("Failed to load dice.qoi: ");
		io::printn(f.nameof);
		return 1;
	}
	io::print("Loaded ");
	io::printn(path);

	// encode that same image to a new QOI blob
	char[]! encoded_data = qoi::encode(input_data, &dice);
	if (catch f = encoded_data) {
		io::print("Failed to encode: ");
		io::printn(f.nameof);
		return 1;
	}

	// save the encoded data to a new file
	File! out = file::open("resources/encoder_test.qoi", "wb");
	if (catch f = out) {
		io::print("Failed to open encoder_test.qoi: ");
		io::printn(f.nameof);
		return 1;
	}
	// write data to file and close it
	usz! written = out.write(encoded_data);
	if (catch f = written) {
		io::print("Failed to write to encoder_test.qoi: ");
		io::printn(f.nameof);
		return 1;
	}
	if (catch f = out.close()) {
		io::print("Failed to close encoder_test.qoi: ");
		io::printn(f.nameof);
		return 1;
	}

	// decode the encoded data
	Desc dice_iterated;
	char[]! decoded_data = qoi::decode(encoded_data, &dice_iterated, Channels.RGBA);
	if (catch f = decoded_data) {
		io::print("Failed to decode: ");
		io::printn(f.nameof);
		return 1;
	}

	// create an Image struct from the data
	raylib::Image image = {
		.data = decoded_data,
		.width = dice_iterated.width,
		.height = dice_iterated.height,
		.mipmaps = 1,
		.format = raylib::PixelFormat.UNCOMPRESSED_R8G8B8A8
	};

	// load image into VRAM
	raylib::Texture2D texture = raylib::load_texture_from_image(image);

	// free the image data
	// mem::free(data);

	raylib::set_target_fps(144);

	while (!raylib::window_should_close())
	{
		raylib::begin_drawing();
			raylib::clear_background({0, 0, 0, 255});
			raylib::draw_texture(texture, 0, 0, raylib::WHITE);
		raylib::end_drawing();
	}
	return 0;
}
