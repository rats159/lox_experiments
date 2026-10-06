package main

import "core:fmt"
import "core:os"
import "core:strings"

C_COMPILER_EXE :: #config(C_COMPILER, "gcc")

error :: proc(message: string, args: ..any) -> ! {
	fmt.eprintfln(message, ..args)
	os.exit(1)
}

build_java :: proc() {
	java_files, err := os.read_directory_by_path(
		"./java/com/craftinginterpreters/lox",
		0,
		context.allocator,
	)

	if err == .Not_Exist {
		error(
			"./java/com/craftinginterpreters/lox does not exist! Are you running this in the right place?",
		)
	} else if err != nil {
		error("Internal error during file loading: %v", os.error_string(err))
	}
	arguments: [dynamic]string
	append(&arguments, "javac")
	append(&arguments, "-cp", "./java")

	actual_java_file_count := 0
	for file in java_files {
		if strings.ends_with(file.name, ".java") {
			actual_java_file_count += 1
			append(&arguments, file.fullpath)
		}
	}

	append(&arguments, "-d", "out/java")

	fmt.printfln("Compiling %d source files with javac.", actual_java_file_count)

	os.make_directory_all("./out/java")

	process, stdout, stderr, odin_err := os.process_exec(
		{command = arguments[:]},
		context.allocator,
	)

	if odin_err != nil {
		error("Failed to run Java compiler: %v", odin_err)
	}

	fmt.print(string(stdout))
	fmt.eprint(string(stderr))

	if len(stderr) == 0 {
		fmt.println("No errors: Built successfully")
	}
}

build_c :: proc() {
	c_files, err := os.read_directory_by_path("./c", 0, context.allocator)

	if err == .Not_Exist {
		error("./c does not exist! Are you running this in the right place?")
	} else if err != nil {
		error("Internal error during file loading: %v", os.error_string(err))
	}

	arguments: [dynamic]string
	append(&arguments, C_COMPILER_EXE)

	actual_c_file_count := 0
	for file in c_files {
		if strings.ends_with(file.name, ".c") {
			actual_c_file_count += 1
			append(&arguments, file.fullpath)
		}
	}
	append(
		&arguments,
		"-Wall",
		"-Werror",
		"-Wextra",
		"-Wpedantic",
		"-std=c99",
		"-Wno-unused-parameter", // tons of `bool canAssign`s
	)
	append(&arguments, "-o", "out/c/clox")

	fmt.printfln(
		"Compiling %d source files with `%s`. Use the command-line define to change the compiler",
		actual_c_file_count,
		C_COMPILER_EXE,
	)

	os.make_directory_all("./out/c")

	process, stdout, stderr, odin_err := os.process_exec(
		{command = arguments[:]},
		context.allocator,
	)

	if odin_err != nil {
		error("Failed to run C compiler: %v", odin_err)
	}

	fmt.print(string(stdout))
	fmt.eprint(string(stderr))

	if len(stderr) == 0 {
		fmt.println("No errors: Built successfully")
	}
}

main :: proc() {
	if len(os.args) < 2 {
		error("Expected at least 1 argument")
	}

	argument := os.args[1]

	switch argument {
	case "java", "jlox":
		build_java()
	case "c", "clox":
		build_c()
	case "test":
		unimplemented("Testing")
	case "help":
		print_help()
	case:
		print_help()
	}
}

print_help :: proc() -> ! {
	fmt.eprintln(
		"""
Builds and/or executes various Lox things:
- c, clox: Builds clox
- java, jlox: Builds jlox
- test: Runs the test suite on clox (TODO)
- help: Prints this message
""",
	)
	os.exit(0)
}
