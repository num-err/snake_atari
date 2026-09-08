do
local _ENV = _ENV
package.preload[ "middleclass" ] = function( ... ) local arg = _G.arg;
local middleclass = {
  _VERSION     = 'middleclass v4.1.1',
  _DESCRIPTION = 'Object Orientation for Lua',
  _URL         = 'https://github.com/kikito/middleclass',
  _LICENSE     = [[
    MIT LICENSE

    Copyright (c) 2011 Enrique García Cota

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

local function _createIndexWrapper(aClass, f)
  if f == nil then
    return aClass.__instanceDict
  elseif type(f) == "function" then
    return function(self, name)
      local value = aClass.__instanceDict[name]

      if value ~= nil then
        return value
      else
        return (f(self, name))
      end
    end
  else -- if  type(f) == "table" then
    return function(self, name)
      local value = aClass.__instanceDict[name]

      if value ~= nil then
        return value
      else
        return f[name]
      end
    end
  end
end

local function _propagateInstanceMethod(aClass, name, f)
  f = name == "__index" and _createIndexWrapper(aClass, f) or f
  aClass.__instanceDict[name] = f

  for subclass in pairs(aClass.subclasses) do
    if rawget(subclass.__declaredMethods, name) == nil then
      _propagateInstanceMethod(subclass, name, f)
    end
  end
end

local function _declareInstanceMethod(aClass, name, f)
  aClass.__declaredMethods[name] = f

  if f == nil and aClass.super then
    f = aClass.super.__instanceDict[name]
  end

  _propagateInstanceMethod(aClass, name, f)
end

local function _tostring(self) return "class " .. self.name end
local function _call(self, ...) return self:new(...) end

local function _createClass(name, super)
  local dict = {}
  dict.__index = dict

  local aClass = { name = name, super = super, static = {},
                   __instanceDict = dict, __declaredMethods = {},
                   subclasses = setmetatable({}, {__mode='k'})  }

  if super then
    setmetatable(aClass.static, {
      __index = function(_,k)
        local result = rawget(dict,k)
        if result == nil then
          return super.static[k]
        end
        return result
      end
    })
  else
    setmetatable(aClass.static, { __index = function(_,k) return rawget(dict,k) end })
  end

  setmetatable(aClass, { __index = aClass.static, __tostring = _tostring,
                         __call = _call, __newindex = _declareInstanceMethod })

  return aClass
end

local function _includeMixin(aClass, mixin)
  assert(type(mixin) == 'table', "mixin must be a table")

  for name,method in pairs(mixin) do
    if name ~= "included" and name ~= "static" then aClass[name] = method end
  end

  for name,method in pairs(mixin.static or {}) do
    aClass.static[name] = method
  end

  if type(mixin.included)=="function" then mixin:included(aClass) end
  return aClass
end

local DefaultMixin = {
  __tostring   = function(self) return "instance of " .. tostring(self.class) end,

  initialize   = function(self, ...) end,

  isInstanceOf = function(self, aClass)
    return type(aClass) == 'table'
       and type(self) == 'table'
       and (self.class == aClass
            or type(self.class) == 'table'
            and type(self.class.isSubclassOf) == 'function'
            and self.class:isSubclassOf(aClass))
  end,

  static = {
    allocate = function(self)
      assert(type(self) == 'table', "Make sure that you are using 'Class:allocate' instead of 'Class.allocate'")
      return setmetatable({ class = self }, self.__instanceDict)
    end,

    new = function(self, ...)
      assert(type(self) == 'table', "Make sure that you are using 'Class:new' instead of 'Class.new'")
      local instance = self:allocate()
      instance:initialize(...)
      return instance
    end,

    subclass = function(self, name)
      assert(type(self) == 'table', "Make sure that you are using 'Class:subclass' instead of 'Class.subclass'")
      assert(type(name) == "string", "You must provide a name(string) for your class")

      local subclass = _createClass(name, self)

      for methodName, f in pairs(self.__instanceDict) do
        if not (methodName == "__index" and type(f) == "table") then
          _propagateInstanceMethod(subclass, methodName, f)
        end
      end
      subclass.initialize = function(instance, ...) return self.initialize(instance, ...) end

      self.subclasses[subclass] = true
      self:subclassed(subclass)

      return subclass
    end,

    subclassed = function(self, other) end,

    isSubclassOf = function(self, other)
      return type(other)      == 'table' and
             type(self.super) == 'table' and
             ( self.super == other or self.super:isSubclassOf(other) )
    end,

    include = function(self, ...)
      assert(type(self) == 'table', "Make sure you that you are using 'Class:include' instead of 'Class.include'")
      for _,mixin in ipairs({...}) do _includeMixin(self, mixin) end
      return self
    end
  }
}

function middleclass.class(name, super)
  assert(type(name) == 'string', "A name (string) is needed for the new class")
  return super and super:subclass(name) or _includeMixin(_createClass(name), DefaultMixin)
end

setmetatable(middleclass, { __call = function(_, ...) return middleclass.class(...) end })

return middleclass
end
end

do
local _ENV = _ENV
package.preload[ "std.strict" ] = function( ... ) local arg = _G.arg;
--[[
 Strict variable declarations for Lua 5.1, 5.2, 5.3 & 5.4.
 Copyright (C) 2006-2023 std.strict authors
]]
--[[--
 Diagnose uses of undeclared variables.

 All variables(including functions!) must be "declared" through a regular
 assignment(even assigning `nil` will do) in a strict scope before being
 used anywhere or assigned to inside a nested scope.

 Use the callable returned by this module to interpose a strictness check
 proxy table to the given environment.   The callable runs `setfenv`
 appropriately in Lua 5.1 interpreters to ensure the semantic equivalence.

 @module std.strict
]]


local setfenv = rawget(_G, 'setfenv') or function() end
local debug_getinfo = debug.getinfo


-- Return callable objects.
-- @function callable
-- @param x an object or primitive
-- @return *x* if *x* can be called, otherwise `nil`
-- @usage
--   (callable(functable) or function()end)(args, ...)
local function callable(x)
   -- Careful here!
   -- Most versions of Lua don't recurse functables, so make sure you
   -- always put a real function in __call metamethods.  Consequently,
   -- no reason to recurse here.
   -- func=function() print 'called' end
   -- func() --> 'called'
   -- functable=setmetatable({}, {__call=func})
   -- functable() --> 'called'
   -- nested=setmetatable({}, {__call=function(self, ...) return functable(...)end})
   -- nested() -> 'called'
   -- notnested=setmetatable({}, {__call=functable})
   -- notnested()
   -- --> stdin:1: attempt to call global 'nested' (a table value)
   -- --> stack traceback:
   -- -->	stdin:1: in main chunk
   -- -->		[C]: in ?
   if type(x) == 'function' or (getmetatable(x) or {}).__call then
      return x
   end
end


-- Return named metamethod, if callable, otherwise `nil`.
-- @param x item to act on
-- @string n name of metamethod to look up
-- @treturn function|nil metamethod function, if callable, otherwise `nil`
local function getmetamethod(x, n)
   return callable((getmetatable(x) or {})[n])
end


-- Length of a string or table object without using any metamethod.
-- @function rawlen
-- @tparam string|table x object to act on
-- @treturn int raw length of *x*
-- @usage
--    --> 0
--    rawlen(setmetatable({}, {__len=function() return 42}))
local function rawlen(x)
   -- Lua 5.1 does not implement rawlen, and while # operator ignores
   -- __len metamethod, `nil` in sequence is handled inconsistently.
   if type(x) ~= 'table' then
      return #x
   end

   local n = #x
   for i = 1, n do
      if x[i] == nil then
         return i -1
      end
   end
   return n
end


-- Deterministic, functional version of core Lua `#` operator.
--
-- Respects `__len` metamethod (like Lua 5.2+).   Otherwise, always return
-- one less than the lowest integer index with a `nil` value in *x*, where
-- the `#` operator implementation might return the size of the array part
-- of a table.
-- @function len
-- @param x item to act on
-- @treturn int the length of *x*
-- @usage
--    x = {1, 2, 3, nil, 5}
--    --> 5 3
--    print(#x, len(x))
local function len(x)
   return (getmetamethod(x, '__len') or rawlen)(x)
end


-- Like Lua `pairs` iterator, but respect `__pairs` even in Lua 5.1.
-- @function pairs
-- @tparam table t table to act on
-- @treturn function iterator function
-- @treturn table *t*, the table being iterated over
-- @return the previous iteration key
-- @usage
--    for k, v in pairs {'a', b='c', foo=42} do process(k, v) end
local pairs = (function(f)
   if not f(setmetatable({},{__pairs=function() return false end})) then
      return f
   end

   return function(t)
      return(getmetamethod(t, '__pairs') or f)(t)
   end
end)(pairs)


-- What kind of variable declaration is this?
-- @treturn string 'C', 'Lua' or 'main'
local function what()
   local d = debug_getinfo(3, 'S')
   return d and d.what or 'C'
end


return setmetatable({
   --- Module table.
   -- @table strict
   -- @string version release version identifier


   --- Require variable declarations before use in scope *env*.
   --
   -- Normally the module @{strict:__call} metamethod is all you need,
   -- but you can use this method for more complex situations.
   -- @function strict
   -- @tparam table env lexical environment table
   -- @treturn table *env* proxy table with metamethods to enforce strict
   --    declarations
   -- @usage
   --   local _ENV = setmetatable({}, {__index = _G})
   --   if require 'std._debug'.strict then
   --      _ENV = require 'std.strict'.strict(_ENV)
   --   end
   --   -- ...and for Lua 5.1 compatibility, without triggering undeclared
   --   -- variable error:
   --   if rawget(_G, 'setfenv') ~= nil then
   --      setfenv(1, _ENV)
   --   end
   strict = function(env)
      -- The set of declared variables in this scope.
      local declared = {}

      --- Environment Metamethods
      -- @section environmentmetamethods

      return setmetatable({}, {
         --- Detect dereference of undeclared variable.
         -- @function env:__index
         -- @string n name of the variable being dereferenced
         __index = function(_, n)
            local v = env[n]
            if v ~= nil then
               declared[n] = true
            elseif not declared[n] and what() ~= 'C' then
               error("variable '" .. n .. "' is not declared", 2)
            end
            return v
         end,

         --- Proxy `len` calls.
         -- @function env:__len
         -- @tparam table t strict table
         __len = function() return len(env) end,

         --- Detect assignment to undeclared variable.
         -- @function env:__newindex
         -- @string n name of the variable being declared
         -- @param v initial value of the variable
         __newindex = function(_, n, v)
            local x = env[n]
            if x == nil and not declared[n] then
               local w = what()
               if w ~= 'main' and w ~= 'C' then
                  error("assignment to undeclared variable '" .. n .. "'", 2)
               end
            end
            declared[n] = true
            env[n] = v
         end,

         --- Proxy `pairs` calls.
         -- @function env:__pairs
         -- @tparam table t strict table
         __pairs = function()
            return pairs(env)
         end,
      })
   end,
}, {
   --- Module Metamethods
   -- @section modulemetamethods

   --- Enforce strict variable declarations in *env*.
   -- @function strict:__call
   -- @tparam table env lexical environment table
   -- @tparam[opt=1] int level stack level for `setfenv`, 1 means
   --    set caller's environment
   -- @treturn table *env* which must be assigned to `_ENV`
   -- @usage
   --   local _ENV = require 'std.strict'(_G)
   __call = function(self, env, level)
      env = self.strict(env)
      setfenv(1 + (level or 1), env)
      return env
   end,

   --- Lazy loading of strict submodules.
   -- Don't load everything on initial startup, wait until first attempt
   -- to access a submodule, and then load it on demand.
   -- @function __index
   -- @string name submodule name
   -- @treturn table|nil the submodule that was loaded to satisfy the missing
   --    `name`, otherwise `nil` if nothing was found
   -- @usage
   --   local strict = require 'std.strict'
   --   local version = strict.version
   __index = function(self, name)
      local ok, t = pcall(require, 'std.strict.' .. name)
      if ok then
         rawset(self, name, t)
         return t
      end
   end,
})
end
end

-- title:   game title
-- author:  game developer, email, etc.
-- desc:    short description
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  lua

local _ENV = require 'std.strict' (_G)

local class = require 'middleclass'
local Vector2 = class('Vector2')

function Vector2:initialize(x, y)
   self.x = x or 0
   self.y = y or 0 
end

function Vector2:add(o)
   self.x = self.x + o.x
   self.y = self.y + o.y
end

local t = 0
local v = Vector2:new(96, 24)
local up = Vector2:new(0, -1)
local down = Vector2:new(0, 1)
local left = Vector2:new(-1, 0)
local right = Vector2:new(1, 0)

function TIC()
   if btn(0) then v:add(up) end
   if btn(1) then v:add(down) end
   if btn(2) then v:add(left) end
   if btn(3) then v:add(right) end

   cls(13)
   spr(1+t%60//30*2,v.x,v.y,14,3,0,0,2,2)
   print("HELLO WORLD!",84,84)
   t=t+1
end

-- <TILES>
-- 001:eccccccccc888888caaaaaaaca888888cacccccccacc0ccccacc0ccccacc0ccc
-- 002:ccccceee8888cceeaaaa0cee888a0ceeccca0ccc0cca0c0c0cca0c0c0cca0c0c
-- 003:eccccccccc888888caaaaaaaca888888cacccccccacccccccacc0ccccacc0ccc
-- 004:ccccceee8888cceeaaaa0cee888a0ceeccca0cccccca0c0c0cca0c0c0cca0c0c
-- 017:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 018:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- 019:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 020:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

