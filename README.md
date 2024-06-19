# Neotest

A framework for interacting with tests within NeoVim.

![image](https://user-images.githubusercontent.com/24252670/166156510-440d9047-c76e-4967-8c17-944399222645.png)

**This is early stage software.**

- [Introduction](#introduction)
- [Installation](#installation)
  - [Supported Runners](#supported-runners)
- [Configuration](#configuration)
- [Usage](#usage)
- [Consumers](#consumers)
  - [Output Window](#output-window)
  - [Summary Window](#summary-window)
  - [Diagnostic Messages](#diagnostic-messages)
  - [Status Signs](#status-signs)
- [Strategies](#strategies)
- [Writing Adapters](#writing-adapters)
  - [Parsing tests in a directory](#parsing-tests)
  - [Collecting results](#collecting-results)

## Introduction

See `:h neotest` for details on neotest is designed and how to interact with it programmatically.

## Installation

[![LuaRocks](https://img.shields.io/luarocks/v/nvim-neotest/neotest?logo=lua&color=purple)](https://luarocks.org/modules/nvim-neotest/neotest)

Neotest uses [nvim-nio](https://github.com/nvim-neotest/nvim-nio) and [plenary.nvim](https://github.com/nvim-lua/plenary.nvim/).

Most adapters will also require [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter).

Neotest uses the `CursorHold` event. This uses the `updatetime`
setting which is by default very high, and lowering this can lead to excessive writes to disk.
It's recommended to use https://github.com/antoinemadec/FixCursorHold.nvim which
allows detaching `updatetime` from the frequency of the `CursorHold` event.
The repo claims it is no longer needed but it is still recommended (See [this issue](https://github.com/antoinemadec/FixCursorHold.nvim/issues/13))

Install with your favourite package manager alongside nvim-dap

[**dein**](https://github.com/Shougo/dein.vim):

```vim
call dein#add("nvim-lua/plenary.nvim")
call dein#add("antoinemadec/FixCursorHold.nvim")
call dein#add("nvim-treesitter/nvim-treesitter")
call dein#add("nvim-neotest/nvim-nio")
call dein#add("nvim-neotest/neotest")
```

[**vim-plug**](https://github.com/junegunn/vim-plug)

```vim
Plug 'nvim-lua/plenary.nvim'
Plug 'antoinemadec/FixCursorHold.nvim'
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'nvim-neotest/nvim-nio'
Plug 'nvim-neotest/neotest'
```

[packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "nvim-neotest/neotest",
  requires = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter"
  }
}
```

[lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter"
  }
}
```

To get started you will also need to install an adapter for your test runner.
See the adapter's documentation for their specific setup instructions.

### Supported Runners

| Test Runner       |                               Adapter                                |
| :---------------- | :------------------------------------------------------------------: |
| pytest            |   [neotest-python](https://github.com/nvim-neotest/neotest-python)   |
| python-unittest   |   [neotest-python](https://github.com/nvim-neotest/neotest-python)   |
| plenary           |  [neotest-plenary](https://github.com/nvim-neotest/neotest-plenary)  |
| go                |         [neotest-go](https://github.com/akinsho/neotest-go) <br> [neotest-golang](https://github.com/fredrikaverpil/neotest-golang) |
| jest              |     [neotest-jest](https://github.com/haydenmeade/neotest-jest)      |
| vitest            |    [neotest-vitest](https://github.com/marilari88/neotest-vitest)    |
| stenciljs         |  [neotest-stenciljs](https://github.com/benelan/neotest-stenciljs)   |
| playwright        |  [neotest-playwright](https://github.com/thenbe/neotest-playwright)  |
| rspec             |     [neotest-rspec](https://github.com/olimorris/neotest-rspec)      |
| minitest          |   [neotest-minitest](https://github.com/zidhuss/neotest-minitest)    |
| dart, flutter     |       [neotest-dart](https://github.com/sidlatau/neotest-dart)       |
| testthat          | [neotest-testthat](https://github.com/shunsambongi/neotest-testthat) |
| phpunit           |   [neotest-phpunit](https://github.com/olimorris/neotest-phpunit)    |
| pest              |       [neotest-pest](https://github.com/V13Axel/neotest-pest)        |
| rust (treesitter) |        [neotest-rust](https://github.com/rouge8/neotest-rust)        |
| rust (LSP)        |        [rustaceanvim](https://github.com/mrcjkb/rustaceanvim)        |
| elixir            |    [neotest-elixir](https://github.com/jfpedroza/neotest-elixir)     |
| dotnet            |    [neotest-dotnet](https://github.com/Issafalcon/neotest-dotnet)    |
| scala             |    [neotest-scala](https://github.com/stevanmilic/neotest-scala)     |
| haskell           |     [neotest-haskell](https://github.com/mrcjkb/neotest-haskell)     |
| deno              |      [neotest-deno](https://github.com/MarkEmmons/neotest-deno)      |
| java              |        [neotest-java](https://github.com/rcasia/neotest-java)        |
| foundry           |    [neotest-foundry](https://github.com/llllvvuu/neotest-foundry)    |
| zig               |      [neotest-zig](https://github.com/lawrence-laz/neotest-zig)      |
| c++ (google test) |       [neotest-gtest](https://github.com/alfaix/neotest-gtest)       |
| gradle            |     [neotest-gradle](https://github.com/weilbith/neotest-gradle)     |
| bash              |        [neotest-bash](https://github.com/rcasia/neotest-bash)        |
| hardhat           |  [neotest-hardhat](https://github.com/TheSnakeWitcher/hardhat.nvim)  |

For any runner without an adapter you can use [neotest-vim-test](https://github.com/nvim-neotest/neotest-vim-test) which supports any runner that vim-test supports.
The vim-test adapter does not support some of the more advanced features such as error locations or per-test output.
If you're using the vim-test adapter then install [vim-test](https://github.com/vim-test/vim-test/) too.

## Configuration

Provide your adapters and other config to the setup function.

```lua
require("neotest").setup({
  adapters = {
    require("neotest-python")({
      dap = { justMyCode = false },
    }),
    require("neotest-plenary"),
    require("neotest-vim-test")({
      ignore_file_types = { "python", "vim", "lua" },
    }),
  },
})
```

See `:h neotest.Config` for configuration options and `:h neotest.setup()` for the default values.

It is highly recommended to use [lazydev.nvim](https://github.com/folke/lazydev.nvim) to enable type checking for neotest to get
type checking, documentation and autocompletion for all API functions.

The default icons use [codicons](https://github.com/microsoft/vscode-codicons).
It's recommended to use this [fork](https://github.com/ChristianChiarulli/neovim-codicons) which fixes alignment issues
for the terminal. If your terminal doesn't support font fallback and you need to have icons included in your font, you can patch it via [Font Patcher](https://github.com/ryanoasis/nerd-fonts#option-8-patch-your-own-font).
There is a simple step by step guide [here](https://github.com/mortepau/codicons.nvim#how-to-patch-fonts).

## Usage

The interface for using neotest is very simple.

Run the nearest test

```lua
require("neotest").run.run()
```

Run the current file

```lua
require("neotest").run.run(vim.fn.expand("%"))
```

Debug the nearest test (requires nvim-dap and adapter support)

```lua
require("neotest").run.run({strategy = "dap"})
```

See `:h neotest.run.run()` for parameters.

Stop the nearest test, see `:h neotest.run.stop()`

```lua
require("neotest").run.stop()
```

Attach to the nearest test, see `:h neotest.run.attach()`

```lua
require("neotest").run.attach()
```

## Consumers

For extra features neotest provides consumers which interact with the state of the tests and their results.

Some consumers will be passive while others can be interacted with.

### Watch Tests

`:h neotest.watch`

Watches files related to tests for changes and re-runs tests

https://user-images.githubusercontent.com/24252670/229367494-6775d7f1-a8fb-461b-bbbd-d6124031293e.mp4

### Output Window

`:h neotest.output`

Displays output of tests
![image](https://user-images.githubusercontent.com/24252670/166143146-e7821fe9-c11c-4e21-9cc0-73989b51e8ed.png)

Displays per-test output
![image](https://user-images.githubusercontent.com/24252670/166143189-0f51b544-3aec-4cfc-93d7-74f3d209aef6.png)

### Output Panel

`:h neotest.output_panel`

Records all output of tests over time in a single window
![image](https://user-images.githubusercontent.com/24252670/201535290-d726c781-a780-4318-b595-a10832b9f191.png)

### Summary Window

`:h neotest.summary`

Displays test suite structure from project root.
![image](https://user-images.githubusercontent.com/24252670/166143333-df8b409f-d6f3-4d3d-a676-5f8a4a4cb8bb.png)

Provides mappings for running, attaching, stopping and showing output.

### Diagnostic Messages

`:h neotest.diagnostic`

Use vim.diagnostic to display error messages where they occur while running.

![image](https://user-images.githubusercontent.com/24252670/166143466-0fdea24c-6f0a-4199-9026-66f89d7d1dbc.png)

### Status Signs

`:h neotest.status`

Displays the status of a test/namespace beside the beginning of the definition.

![image](https://user-images.githubusercontent.com/24252670/166143402-b318ef91-c053-4973-b929-5ee97572f2c2.png)

See the help doc for a list of all consumers and their documentation.

## Strategies

Strategies are methods of running tests. They provide the functionality to attach to running processes and so attaching
will mean different things for different strategies.

|    Name    | Description                                                                                                 |
| :--------: | :---------------------------------------------------------------------------------------------------------- |
| integrated | Default strategy that will run a process in the background and allow opening a floating terminal to attach. |
|    dap     | Uses nvim-dap to debug tests (adapter must support providing an nvim-dap configuration)                     |

Custom strategies can implemented by providing a function which takes a `neotest.RunSpec` and returns an table that fits the `neotest.Process`
interface. Plenary's async library can be used to run asynchronously.

## Writing Adapters

This section is for people wishing to develop their own neotest adapters.
The documentation here and the underlying libraries are WIP and open to feedback/change.
Please raise issues with any problems understanding or using the this doc.
The best place to figure out how to create an adapter is by looking at the existing ones.

Adapters must fulfill an interface to run (defined
[here](https://github.com/nvim-neotest/neotest/blob/master/lua/neotest/adapters/interface.lua)).

Much of the functionality is built around using a custom tree object that defines the structure of the test suite.
There are helpers that adapters can use within their code (all defined under `neotest.lib`)

Adapters must solve three problems:

1. Parse tests
2. Construct test commands
3. Collect results

### Parsing Tests

There are two stages to this, finding files which is often a simple file name check (it's OK if a test file has no
actual tests in it) and parsing test files.

For languages supported by nvim-treesitter, the easiest way to parse tests is to use the neotest treesitter wrapper to parse a query to
constuct a tree structure.

The query can define capture groups for tests and namespaces. Each type must have `<type>.name` and `<type>.definition`
capture groups. They can be used multiple times in the query

Example from neotest-plenary:

```lua
local lib = require("neotest.lib")

function PlenaryNeotestAdapter.discover_positions(path)
  local query = [[
  ;; describe blocks
  ((function_call
      name: (identifier) @func_name (#match? @func_name "^describe$")
      arguments: (arguments (_) @namespace.name (function_definition))
  )) @namespace.definition


  ;; it blocks
  ((function_call
      name: (identifier) @func_name
      arguments: (arguments (_) @test.name (function_definition))
  ) (#match? @func_name "^it$")) @test.definition

  ;; async it blocks (async.it)
  ((function_call
      name: (
        dot_index_expression
          field: (identifier) @func_name
      )
      arguments: (arguments (_) @test.name (function_definition))
    ) (#match? @func_name "^it$")) @test.definition
    ]]
  return lib.treesitter.parse_positions(path, query, { nested_namespaces = true })
end
```

For languages unsupported by treesitter you can use regexes like neotest-vim-test or hook into the test runner.

### Constructing Test Commands

This is the easiest part of writing an adapter. You need to handle the different types of positions that a user may run
(directory, file, namespace and test).

If you are hooking into the runner, you may not be running the test runner command directly. neotest-python and
neotest-plenary both are examples of this, with a script being used to run each runner to handle parsing results and
storing them for result collection later.

### Collecting Results

Collecting results will be the most involved process in the adapter, with complexity depending on the test runner and
desired features.

For the most basic implementation an adapter can choose to only run tests individually and use the exit code as an
indicator of the result (this is how neotest-vim-test works) but this impacts peformance and also loses out on more
advanced features.

If tests can be run together then the adapter must provide results for at least each individual test. Results for
namespaces, files and directories will be inferred from their child tests.

For collecting test specific error messages, error locations etc you'll need to parse output or hook into the runner.
See neotest-python and neotest-plenary for examples on how this can be done.
