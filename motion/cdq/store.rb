
module CDQ

  class CDQStoreManager

    attr_writer :current

    def initialize(opts = {})
      @config = opts[:config] || CDQConfig.default
      @model_manager = opts[:model_manager]
    end

    def current
      @current ||= create_store
    end

    def reset!
      NSFileManager.defaultManager.removeItemAtURL(@config.database_url, error: nil)
    end

    def invalid?
      !@current && @model_manager.invalid?
    end

    private

    def create_store
      if invalid?
        raise "No model found.  Can't create a persistent store coordinator without it."
      else
        coordinator = NSPersistentStoreCoordinator.alloc.initWithManagedObjectModel(@model_manager.current)
        error = Pointer.new(:object)
        options = { NSMigratePersistentStoresAutomaticallyOption => true,
                    NSInferMappingModelAutomaticallyOption => true }
        url = @config.database_url
        mkdir_p File.dirname(url.path)
        store = coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
                                                       configuration:nil,
                                                       URL:url,
                                                       options:options,
                                                       error:error)
        if store.nil?
          error[0].userInfo['metadata'] && error[0].userInfo['metadata'].each do |key, value|
            NSLog "#{key}: #{value}"
          end
          raise error[0].userInfo['reason']
        end
        coordinator
      end
    end
    
    def mkdir_p dir
      error = Pointer.new(:object)
      m = NSFileManager.defaultManager
      r = m.createDirectoryAtPath dir, withIntermediateDirectories:true, attributes:nil, error:error
      unless r
        NSLog "#{error[0].localizedDescription}"
        raise error[0].localizedDescription
      end
    end
    
  end

end
