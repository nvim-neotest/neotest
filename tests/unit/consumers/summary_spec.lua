local Tree = require("neotest.types").Tree
local grouping = require("neotest.consumers.summary.grouping")
local Component = require("neotest.consumers.summary.component")
local Canvas = require("neotest.consumers.summary.canvas")
local config = require("neotest.config")
local stub = require("luassert.stub")

describe("directory-grouped summary", function()
  local function tree(filename)
    return Tree.from_list({
      { id = "/project", path = "/project", name = "project", type = "dir" },
      {
        { id = "/project/src", path = "/project/src", name = "src", type = "dir" },
        {
          {
            id = "/project/src/" .. filename,
            path = "/project/src/" .. filename,
            name = filename,
            type = "file",
          },
          {
            id = filename .. "::test",
            path = "/project/src/" .. filename,
            name = "a test",
            type = "test",
            range = { 0, 0, 1, 0 },
          },
        },
      },
    }, function(pos)
      return pos.id
    end)
  end

  local client, trees, component, merged, references
  before_each(function()
    trees = { vitest = tree("component.test.tsx"), playwright = tree("journey.test.ts") }
    client = {
      get_position = function(_, id, args)
        return id and trees[args.adapter]:get_key(id) or trees[args.adapter]
      end,
      get_results = function(_, adapter)
        return { ["/project/src"] = { status = adapter == "vitest" and "passed" or "failed" } }
      end,
      is_running = function()
        return false
      end,
    }
    merged, references = grouping.directory(client, { "vitest", "playwright" })
    component = Component(client, "directory")
    component.references = references
  end)

  local function render()
    local canvas = Canvas.new(config.summary)
    component:render(canvas, merged, { ["/project"] = true, ["/project/src"] = true })
    return canvas
  end

  it("renders shared directories once and preserves both files", function()
    local canvas = render()
    local text = table.concat(canvas.lines, "\n")
    local _, directories = text:gsub("src", "")
    assert.equals(1, directories)
    assert.truthy(text:find("component.test.tsx", 1, true))
    assert.truthy(text:find("journey.test.ts", 1, true))
    assert.equals(2, #trees.vitest:to_list())
    assert.equals("/project", trees.vitest:data().id)
    assert.equals("failed", component:_get_status(merged:get_key("/project/src"):data()))
  end)

  it("runs shared directories through both adapters and files through their owner", function()
    local calls = {}
    local neotest = require("neotest")
    require("neotest").setup({ adapters = {}, summary = { animated = false } })
    stub(neotest.run, "run", function(args)
      calls[#calls + 1] = args
    end)
    local canvas = render()
    local function activate(action, name)
      for line, text in ipairs(canvas.lines) do
        if text:find(name, 1, true) then
          for _, callback in ipairs(canvas.mappings[action][line]) do
            callback()
          end
          return
        end
      end
      error("Missing summary row: " .. name)
    end
    activate("run", "src")
    assert.equals(2, #calls)
    assert.equals("/project/src", calls[1][1])
    assert.not_equals(calls[1].adapter, calls[2].adapter)
    calls = {}
    activate("run", "journey.test.ts")
    assert.same({ { "/project/src/journey.test.ts", adapter = "playwright" } }, calls)
    neotest.run.run:revert()
  end)

  it("renders the grouped view in the summary window", function()
    local nio = require("nio")
    local done = false
    nio.run(function()
      config.summary.group_by = "directory"
      config.summary.animated = false
      client.get_adapters = function()
        return { "vitest", "playwright" }
      end
      local summary = require("neotest.consumers.summary.summary")(client)
      summary:set_starting()
      summary:set_started()
      summary:open()
      summary:render()
      local function text()
        return table.concat(vim.api.nvim_buf_get_lines(summary.win:buffer(), 0, -1, false), "\n")
      end
      assert(vim.wait(3000, function()
        return text():find("project", 1, true) ~= nil
      end))
      assert.is_nil(text():find("vitest", 1, true))
      -- Expand the shared path through the same render event used by mappings.
      summary:render({ ["/project"] = true, ["/project/src"] = true })
      assert(vim.wait(3000, function()
        return text():find("journey.test.ts", 1, true) ~= nil
      end))
      assert.truthy(text():find("component.test.tsx", 1, true))
      local _, count = text():gsub("src", "")
      assert.equals(1, count)
      summary:close()
      config.summary.group_by = "adapter"
      done = true
    end)
    assert(
      vim.wait(5000, function()
        return done
      end),
      "Grouped summary did not render"
    )
  end)

  it("keeps overlapping file and test IDs adapter-qualified", function()
    trees.playwright = tree("component.test.tsx")
    local result, refs = grouping.directory(client, { "vitest", "playwright" })
    local files = result:get_key("/project/src"):children()
    assert.equals(2, #files)
    assert.not_equals(files[1]:data().id, files[2]:data().id)
    assert.truthy(files[1]:data().name:find("[", 1, true))
    assert.equals(1, #refs[files[1]:data().id])
  end)
end)
