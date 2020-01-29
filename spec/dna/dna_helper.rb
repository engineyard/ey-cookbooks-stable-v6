require 'dnapi'

def set_dna(node, dna_name)
  dna_file = File.expand_path("../dna_files/#{dna_name}.json", __FILE__)
  set_dna_from_file(node, dna_file)
end

def set_dna_from_file(node, dna_file)
  dna = JSON.parse(IO.read(dna_file))
  yield dna if block_given?
  node.default['dna'] = dna
end

def set_dnapi_environment(node)
  dna = DNApi.build
  yield dna if block_given?
  node.default['dna'] = dna.to_hash
end
