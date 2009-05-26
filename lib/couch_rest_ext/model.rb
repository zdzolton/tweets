module CouchRestExt
  class Model < CouchRest::ExtendedDocument
  
    # NB: This base class will serve to contain all the extensions on top of CouchRest::ExtendedDocument
    # that we need. It is NOT a place for application-specfic functionality!
    
    use_database COUCHDB.default_database
  
    include CouchRest::Validation
    include CouchRestExt::Associations
    # extend CouchRestExt::ValidatesUnique
    # include CouchRestExt::Whitelisting
    
    define_callbacks :validation
    def valid?(context = :default)
      _run_validation_callbacks do
        self.class.validators.execute(context, self)
      end
    end
    
    def self.instantiate doc
      doc['couchrest-type'].constantize.new(doc)
    end
    
    def self.get_all(ids)
      database.documents(:keys => ids, :include_docs => true)['rows'].map do |row|
        doc = row['doc']
        instantiate doc unless doc.nil?
      end
    end
    
    def self.get(id)
      instantiate database.get(id.split('-').first)
    end
    
    def self.create(attributes={})
      returning self.new(attributes) do |model|
        yield model if block_given?
        model.save
      end
    end
    
    # copied from ExtendedDocument, so that we can add custom behavior around setting attributes
    def initialize(passed_keys={})
      apply_defaults # defined in CouchRest::Mixins::Properties
      # custom behavior so that attributes will go through setter, if one exists
      passed_keys ||= {}
      passed_keys.each do |k,v|
        setter = "#{k}="
        if self.respond_to?(setter)
          self.send(setter, v)
        else
          self[k.to_s] = v
        end
      end
      cast_keys      # defined in CouchRest::Mixins::Properties
      unless self['_id'] && self['_rev']
        self['couchrest-type'] = self.class.to_s
      end
    end
    
    def self.search query, options={}
      get_all self.database.search(query, options)['rows'].map{ |row| row['_id'] }
    end
    
    def to_param
      id
    end
    
    def inspect
      "#<#{self.class} #{self.to_a.sort_by(&:first).map {|pair| "#{pair[0]}: #{pair[1].to_s}"}.join(", ")}>"
    end
    
    def self.logger
      Rails.logger
    end
    
    def logger
      self.class.logger
    end
    
    def self.count view_name=nil, query_opts={}
      query_opts.merge!(:raw => true)
      if view_name.blank?
        self.all(query_opts.merge(:limit => 0))['total_rows']
      else
        self.send(view_name, query_opts)['rows'].size
      end
    end
    
  private
    
    def self.fetch_view_with_docs(db, name, opts, raw=false, &block)
      if raw || (opts.has_key?(:include_docs) && opts[:include_docs] == false)
        fetch_view(db, name, opts, &block)
      else
        begin
          view = fetch_view db, name, opts.merge({:include_docs => true}), &block
          view['rows'].collect{|r|r['doc']['couchrest-type'].constantize.new(r['doc'])} if view['rows']
        rescue
          # fallback for old versions of couchdb that don't 
          # have include_docs support
          view = fetch_view(db, name, opts, &block)
          view['rows'].collect{|r|r['doc']['couchrest-type'].constantize.new(db.get(r['id']))} if view['rows']
        end
      end
    end
    
  end
end
