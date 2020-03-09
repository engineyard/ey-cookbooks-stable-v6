cookbook_file "/root/snaps_remove.sh" do
  source "snaps_remove.sh"
  mode "744"
end


execute "Remove snaps from all instances" do
  command "/root/snaps_remove.sh"
  only_if { File.exists?("/root/snaps_remove.sh") }
end
