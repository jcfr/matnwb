%given filename, outputs matnwb
function nwb = nwbRead(filename)
validateattributes(filename, {'char', 'string'}, {'scalartext'});
info = h5info(filename);

g = util.StructMap();
if ~isempty(info.Groups)
  g = processGroups(info.Groups, filename);
end

d = util.StructMap();
if ~isempty(info.Datasets)
  d = processDatasets(info.Datasets, '', filename);
end

l = util.StructMap();
if ~isempty(info.Links)
  l = processLinks(info.Links);
end

a = util.StructMap();
if ~isempty(info.Attributes)
  a = processAttributes(info.Attributes);
end

kwa = struct2kwargs(d, l, a);
if ~isempty(fieldnames(g))
  kwa = cat(2, kwa, {'groups' g});
end
nwb = matnwb(kwa{:});
end

function s = process(propList, func)
validateattributes(propList, {'struct', 'util.StructMap'}, {'vector'});
s = util.StructMap();
for i=1:length(propList)
  if isstruct(propList) 
    prop = util.StructMap(propList(i));
  else
    prop = propList(i);
  end
  path = prop.Name;
  v = func(prop);
  if isa(v, 'util.StructMap')
    s = util.structUniqUnion(s, v);
  else
    s.(path2name(path)) = v;
  end
end
end

function group = processGroups(glist, filename)
  function v = procFun(g)
    go = util.StructMap();
    
    if ~isempty(g.Groups)
      go.groups = processGroups(g.Groups, filename);
    end
    
    if ~isempty(g.Datasets)
      go.datasets = processDatasets(g.Datasets, g.Name,filename);
    end
    
    if ~isempty(g.Links)
      go.links = processLinks(g.Links);
    end
    
    if ~isempty(g.Attributes)
      go.attributes = processAttributes(g.Attributes);
    end
    
    v = types.untyped.Group(go);
  end
group = process(glist, @procFun);
end

function attrobj = processAttributes(alist)
attrobj = process(alist, @(a) a.Value);
end

function dsobj = processDatasets(dlist, path, filename)
  function v = procFun(d)
    fp = [path '/' d.Name];
    if isempty(d.Attributes)
      v = h5read(filename, fp);
    else
      v = processAttributes(d.Attributes);
      afields = fieldnames(v);
      for i=1:length(afields)
        af = afields{i};
        v.([d.Name '_' af]) = v.(af);
        v = rmfield(v, af);
      end
      v.(d.Name) = h5read(filename, fp);
    end
  end
dsobj = process(dlist, @procFun);
end

function lnkobj = processLinks(llist)
  function v = procFun(l)
    data = l.Value;
    v = types.untyped.Link(data{:});
  end
lnkobj = process(llist, @procFun);
end

function nm = path2name(path)
validateattributes(path, {'char', 'string'}, {'scalartext'});
splitpath = strsplit(path, '/');
nm = splitpath{end};
end

function kwa = struct2kwargs(varargin)
kwa = {};
for n=1:nargin
  s = varargin{n};
  validateattributes(s, {'util.StructMap'}, {'scalar'});
  
  fnms = fieldnames(s);
  offset = length(kwa);
  kwa = cat(2, kwa, cell(1, length(fnms)*2));
  for i=1:length(fnms)
    fnm = fnms{i};
    kwa{i*2-1+offset} = fnm;
    kwa{i*2+offset} = s.(fnm);
  end
end
end