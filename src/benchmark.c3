module qoi::benchmark;

import std::io;
import std::time;

const RUNS = 100;
const REPETITIONS = 30;

// TODO: Implement a full benchmark suite or idk

fn void test()
{

	time::Time[REPETITIONS] times;

	// // load a QOI image
	// Desc dice;
	// char[]! data = qoi::read("resources/dice.qoi", &dice, Channels.RGBA);
	// if (catch f = data)
	// {
	// 	io::print("Failed to load dice.qoi: ");
	// 	io::printn(f.nameof);
	// }
	// io::printn("Loaded dice.qoi for testing");

	
	// read file
	char[]! data = file::load_new("resources/dice.qoi");
	if (catch data) return;
	defer mem::free(data);
	Desc dice;

	for (uint i = 0; i < REPETITIONS; i++)
	{
		time::Time start = time::now();

		for (uint j = 0; j < RUNS; j++)
		{
			// encode that same image to a new QOI blob
			// usz! written = qoi::write("resources/encoder_test_2.qoi", data, &dice);
			// if (catch f = written)
			// {
			// 	io::print("Failed to encode: ");
			// 	io::printn(f.nameof);
			// 	continue;
			// }
			char[]! decoded = qoi::decode(data, &dice, Channels.RGBA);
			if (catch f = decoded)
			{
				io::print("Failed to decode: ");
				io::printn(f.nameof);
				continue;
			}
			mem::free(decoded);
		}

		time::Time end = time::now();
		times[i] = end - start;
	}

	// get minimum time
	time::Time min = times[0];
	time::Time total = 0;
	for (uint i = 0; i < REPETITIONS; i++)
	{
		if (times[i] < min) min = times[i];
		total += times[i];
	}

	io::printn("Minimum time: ");
	io::print(min);
	io::printn(" us");
	io::printn("Average time: ");
	io::print(total / REPETITIONS);
	io::printn(" us");
	io::printn("Minimum time for one run: ");
	io::print((float)min / RUNS / 1000); // in ms
	io::printn(" ms");
}
