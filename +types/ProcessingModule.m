classdef ProcessingModule < types.NWBContainer

  properties
    description;
  end

  methods %constructor
    function obj = ProcessingModule(varargin)
      p = inputParser;
      p.KeepUnmatched = true;
      p.addParameter('description', {});
      p.addParameter('groups', struct());
      p.parse(varargin{:});
      obj = obj@types.NWBContainer(varargin{:});
      obj.help = {'A collection of analysis outputs from processing of data'};
      fn = fieldnames(p.Results);
      if ~isempty(fn)
        for i=1:length(fn)
          field = fn{i};
          if ~strcmp(field, 'groups')
            obj.(field) = p.Results.(field);
          end
        end
      end
      gn = fieldnames(p.Results.groups);
      if ~isempty(gn)
        for i=1:length(gn)
          gnm = gn{i};
          if isfield(obj, gnm)
            error('Naming conflict found in ProcessingModule object property name: ''%s''', gnm);
          else
            addprop(obj, gnm);
            obj.(gnm) = p.Results.groups.(gnm);
          end
        end
      end
    end
  end

  methods %setters
  end

  methods(Access=protected) %validators
  end

  methods  %export
    function export(obj, loc_id)
      export@types.NWBContainer(obj, loc_id);
      h5util.writeAttribute(loc_id, 'description', obj.description, 'string');
      plist = 'H5P_DEFAULT';
      fnms = fieldnames(obj);
      for i=1:length(fnms)
        fnm = fnms{i};
        if isa(fnm, 'Group')
          gid = H5G.create(loc_id, fnm, plist, plist, plist);
          export(obj.(fnm), gid);
          H5G.close(gid);
        end
      end
    end
  end
end