local Tree = require("neotest.types").Tree

local M = {}

---Build a display-only tree. Adapter position IDs and trees remain untouched.
function M.directory(client, adapter_ids)
  local root = { { id = "neotest-summary", type = "dir", name = "Tests", path = "" } }
  local directories = {}
  local references = {}
  local files = {}
  local function add(tree, parent, adapter)
    local original = tree:data()
    local id = original.type == "dir" and original.path or adapter .. "\0" .. original.id
    local node = original.type == "dir" and directories[id] or nil
    if not node then
      local position = vim.tbl_extend("force", original, { id = id, original_id = original.id })
      node = { position }
      parent[#parent + 1] = node
      if original.type == "dir" then
        directories[id] = node
      end
      if original.type == "file" then
        files[original.path] = files[original.path] or {}
        table.insert(files[original.path], { position = position, adapter = adapter })
      end
    end
    references[id] = references[id] or {}
    table.insert(references[id], { adapter = adapter, id = original.id })
    for _, child in ipairs(tree:children()) do
      add(child, node, adapter)
    end
  end
  -- Insert ancestor roots first so nested adapter roots share their directory.
  local ordered = vim.list_extend({}, adapter_ids)
  table.sort(ordered, function(a, b)
    return client:get_position(nil, { adapter = a }):data().path
      < client:get_position(nil, { adapter = b }):data().path
  end)
  for _, adapter in ipairs(ordered) do
    local tree = client:get_position(nil, { adapter = adapter })
    local parent = root
    local path = vim.fn.fnamemodify(tree:data().path, ":h")
    while path ~= "." and path ~= "/" do
      if directories[path] then
        parent = directories[path]
        break
      end
      local next_path = vim.fn.fnamemodify(path, ":h")
      if next_path == path then
        break
      end
      path = next_path
    end
    add(tree, parent, adapter)
  end
  for _, entries in pairs(files) do
    if #entries > 1 then
      for _, entry in ipairs(entries) do
        entry.position.name = entry.position.name .. " [" .. entry.adapter:match("^[^:]+") .. "]"
      end
    end
  end
  local function sort(node)
    local children = {}
    for i = 2, #node do
      children[#children + 1] = node[i]
    end
    -- Preserve adapter-defined test ordering; only sort filesystem entries.
    if node[1].type == "dir" then
      table.sort(children, function(a, b)
        if a[1].type ~= b[1].type then
          return a[1].type == "dir"
        end
        return a[1].name < b[1].name
      end)
    end
    for i, child in ipairs(children) do
      node[i + 1] = child
      sort(child)
    end
  end
  sort(root)
  return Tree.from_list(root, function(position)
    return position.id
  end), references
end

return M
