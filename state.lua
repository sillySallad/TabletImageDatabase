local state = {}

function state.config()
	if not state._config then
		local Configuration = require "Configuration"
		state._config = Configuration.create("config.txt")
	end
	return state._config
end

function state.database()
	if not state._database then
		local Database = require "Database"
		state._database = Database.create(state.config():str("DatabaseLocation", "database"))
	end
	return state._database
end

function state.searchView()
	if not state._search_view then
		local SearchView = require "SearchView"
		local database = state.database()
		state._search_view = SearchView.create(database)
	end
	return state._search_view
end

function state.imageCache()
	if not state._image_cache then
		local ImageCache = require "ImageCache"
		state._image_cache = ImageCache.create()
	end
	return state._image_cache
end

function state.currentView()
	if not state._current_view then
		state._current_view = state.searchView()
	end
	return state._current_view
end

function state.tagDatabase()
	if not state._tag_database then
		local TagDatabase = require "TagDatabase"
		state._tag_database = TagDatabase.create(state.config():str("TagDatabaseLocation", "tags"))
	end
	return state._tag_database
end

function state.setCurrentView(view)
	state._current_view = view
end

state.debug = true
state.swap_panels = false

return state
