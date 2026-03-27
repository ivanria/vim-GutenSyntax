
# vim-GutenSyntax

**vim-GutenSyntax** is an automated, asynchronous syntax highlighting extension for Vim 9.1+. It is a specialized fork of [vim-gutentags](https://github.com) by Ludovic Chabant.

While the original Gutentags focuses on tag-based navigation, **GutenSyntax** leverages those tags to dynamically generate and apply syntax highlighting for your project's custom `struct`, `union`, `enum`, and `#define` declarations.

## Key Features

*   **Dynamic Highlighting**: Automatically colors your custom types and macros as you define them.
*   **Asynchronous**: Uses Vim 9 jobs to parse tags in the background—no UI freezes, even on the Linux Kernel.
*   **Self-Cleaning**: Automatically removes highlighting for deleted code (no "phantom" tags).
*   **Zero-Config for C**: Hardcoded defaults optimized for C, C++, Yacc, and Flex.

## How It Works

GutenSyntax hooks into the Gutentags lifecycle. When tags are updated, a background shell process (`sed` + `sort`) generates a local syntax file (`__local_syntax.vim`) in your project root. This file is then silently sourced across all open windows using `win_execute`.

## Pre-Configured Variables

To ensure consistent behavior, the following `gutentags` variables are pre-set within the plugin:


| Variable | Value | Purpose |
| :--- | :--- | :--- |
| `g:gutentags_project_root` | `['__gutentags_enable_file']` | Only activates in folders containing this file. |
| `g:gutentags_ctags_tagfile` | `__ctags_syntax_src` | Internal tag source for syntax generation. |
| `g:gutentags_ctags_extra_args` | `[...C, C++, Make...]` | Restricts scanning to specific languages. |
| `g:gutentags_generate_on_write`| `1` | Updates highlighting every time you save. |

*Note: These are hardcoded in `plugin/gutentags.vim`. To override them, you must edit that file directly.*

## Installation

1. Clone the repository into your Vim packages or use your favorite plugin manager.
2. Ensure `ctags` (Universal Ctags recommended) is installed.
3. To enable the plugin for a project, create an empty file named `__gutentags_enable_file` in the project root.

## License

Modified by Ivan Riabtsov (2025). Licensed under the MIT license (same as original vim-gutentags).
