module Plugins
   def Plugins.register(plugin_module)
      @@plugins << plugin_module
   end

   def Plugins.invoke(action, *arguments)
      @@plugins.each do |plugin|
         if plugin.respond_to?(action)
            plugin.send(action, *arguments)
         end
      end
   end

   def Plugins.init
      @@plugins = []
   end
end

Plugins.init

cwd = File.dirname(__FILE__)
Dir.glob(File.join(cwd, '../plugins/*.rb')).each do |file|
   require file
end

