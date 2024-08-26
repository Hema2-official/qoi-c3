module qoi::benchmark;

import std::io;
import std::time;

const RUNS = 100;
const REPETITIONS = 30;

// TODO: Implement a full benchmark suite or idk

macro @repeat_test(block, ...)
{
	time::Time[REPETITIONS] times;

	for (uint i = 0; i < REPETITIONS; i++)
	{
		// record start time
		time::Time start = time::now();

		// run the test block RUNS times
		for (uint j = 0; j < RUNS; j++)
		{
			block($vasplat);
		}

		// record end time and note the duration
		time::Time end = time::now();
		times[i] = end - start;
	}

	// find minimum and add up all times
	time::Time min = times[0];
	time::Time total = 0;
	for (uint i = 0; i < REPETITIONS; i++)
	{
		if (times[i] < min) min = times[i];
		total += times[i];
	}

	// print statistics
	io::printfn("Average time per %d runs: ", RUNS);
	io::printfn("%.6f ms", (float)total / REPETITIONS / 1000);

	io::printfn("Minimum time per %d runs: ", RUNS);
	io::printfn("%.6f ms", (float)min / 1000);

	io::printfn("Minimum time for one run: ");
	io::printfn("%.6f ms", (float)min / RUNS / 1000);

	io::printn();
}


fn void test_decode()
{
	io::printn("Running test: decode");

	String file_path = "resources/dice.qoi";

	@pool() {
		// create empty descriptor
		Desc dice;

		// read file
		char[]! qoi_data = file::load_new(file_path);
		if (catch qoi_data) {
			io::printfn("Failed to run test: could not load %s", file_path);
			return;
		};

		// run decode test
		@repeat_test(
			fn void(char[] data, Desc* desc) {
				// decode the QOI image
				char[]! decoded = qoi::decode(data, desc, Channels.RGBA);
				if (catch f = decoded)
				{
					io::print("Failed to decode: ");
					io::printn(f.nameof);
					return;
				}
				mem::free(decoded);
			},
			qoi_data,
			&dice
		);
	};
}

fn void test_encode()
{
	io::printn("Running test: encode");

	String file_path = "resources/dice.qoi";

	@pool() {
		// create empty descriptor
		Desc dice;

		// load a QOI image
		char[]! image = qoi::read(file_path, &dice, Channels.RGBA);
		if (catch f = image)
		{
			io::printfn("Failed to load %s: %s", file_path, f.nameof);
			return;
		}

		// run encode test
		@repeat_test(
			fn void(char[] data, Desc* desc) {
				// encode the decoded image
				char[]! encoded = qoi::encode(data, desc);
				if (catch f = encoded)
				{
					io::print("Failed to encode: ");
					io::printn(f.nameof);
					return;
				}
				mem::free(encoded);
			},
			image,
			&dice
		);
	};

	// // encode that same image to a new QOI blob
	// usz! written = qoi::write("resources/encoder_test_2.qoi", data, &dice);
	// if (catch f = written)
	// {
	// 	io::print("Failed to encode: ");
	// 	io::printn(f.nameof);
	// 	continue;
	// }
}

fn void test_read()
{
	io::printn("Running test: read");

	String file_path = "resources/dice.qoi";

	@pool() {
		// create empty descriptor
		Desc dice;

		// run read test
		@repeat_test(
			fn void(String path, Desc* desc) {
				// read the QOI image
				char[]! data = qoi::read(path, desc, Channels.RGBA);
				if (catch f = data)
				{
					io::print("Failed to read: ");
					io::printn(f.nameof);
					return;
				}
				mem::free(data);
			},
			file_path,
			&dice
		);
	};
}

fn void test_write()
{
	io::printn("Running test: write");

	String file_path = "resources/dice.qoi";
	String output_path = "resources/encoder_benchmark.qoi";

	@pool() {
		// create empty descriptor
		Desc dice;

		// load a QOI image
		char[]! image = qoi::read(file_path, &dice, Channels.RGBA);
		if (catch f = image)
		{
			io::printfn("Failed to load %s: %s", file_path, f.nameof);
			return;
		}

		// run write test
		@repeat_test(
			fn void(char[] data, Desc* desc, String output_path) {
				// encode the decoded image
				usz! written = qoi::write(output_path, data, desc);
				if (catch f = written)
				{
					io::print("Failed to write: ");
					io::printn(f.nameof);
					return;
				}
			},
			image,
			&dice,
			output_path
		);

		// delete the file
		if (catch f = file::delete(output_path))
		{
			io::printfn("Failed to delete %s: %s", );
		}
	};
}

fn void test_all()
{
	test_decode();
	test_encode();
	test_read();
	test_write();
}
