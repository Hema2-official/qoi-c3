module qoi::benchmark;

import std::io;
import std::time;

const RUNS = 100;
const REPETITIONS = 10;

struct BenchmarkResult
{
	time::Time avg; // avg time per single run
	Desc desc;		// descriptor of the image
}

fault BenchmarkError
{
	FILE_OPEN_FAILED,
}

macro time::Time @repeat_test(block, ...)
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

	return total / REPETITIONS / RUNS;
}


fn BenchmarkResult! test_decode(String file_path)
{
	@pool() {
		// create empty descriptor
		Desc desc;

		// read file
		char[]! qoi_data = file::load_new(file_path);
		if (catch qoi_data) {
			io::printfn("Failed to run test: could not load %s", file_path);
			return BenchmarkError.FILE_OPEN_FAILED?;
		};

		// run decode test
		time::Time avg = @repeat_test(
			fn void(char[] data, Desc* desc) {
				// decode the QOI image
				char[]! decoded = qoi::decode(data, desc, Channels.AUTO);
				if (catch f = decoded)
				{
					io::print("Failed to decode: ");
					io::printn(f.nameof);
					return;
				}
				mem::free(decoded);
			},
			qoi_data,
			&desc
		);

		return {
			.avg = avg,
			.desc = desc
		};
	};
}

fn BenchmarkResult! test_encode(String file_path)
{
	@pool() {
		// create empty descriptor
		Desc desc;

		// load a QOI image
		char[]! image = qoi::read(file_path, &desc, Channels.AUTO);
		if (catch f = image)
		{
			io::printfn("Failed to load %s: %s", file_path, f.nameof);
			return BenchmarkError.FILE_OPEN_FAILED?;
		}

		// run encode test
		time::Time avg = @repeat_test(
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
			&desc
		);

		return {
			.avg = avg,
			.desc = desc
		};
	};
}

fn void test_all(String file_path)
{
	BenchmarkResult! decode_result = test_decode(file_path);
	BenchmarkResult! encode_result = test_encode(file_path);

	if (catch f = decode_result) {
		io::printfn("Failed to run test: %s", f.nameof);
		return;
	};
	if (catch f = encode_result) {
		io::printfn("Failed to run test: %s", f.nameof);
		return;
	};

	uint pixels = decode_result.desc.width * decode_result.desc.height;
	float decode_mpps = (float)pixels / (float)decode_result.avg;
	float encode_mpps = (float)pixels / (float)encode_result.avg;

	io::printfn("%s %dx%d", file_path, decode_result.desc.width, decode_result.desc.height);
	io::printfn("decode: %.3f ms, %.3f MPPS", (float)decode_result.avg / 1000, decode_mpps);
	io::printfn("encode: %.3f ms, %.3f MPPS", (float)encode_result.avg / 1000, encode_mpps);
}
