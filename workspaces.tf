
# Register Directory with WorkSpaces
resource "aws_workspaces_directory" "main" {
  depends_on   = [time_sleep.wait_for_ad_connector]
  directory_id = aws_directory_service_directory.ad_connector.id
  subnet_ids   = aws_subnet.workspaces[*].id
  self_service_permissions {
    change_compute_type  = true
    increase_volume_size = true
    rebuild_workspace    = true
    restart_workspace    = true
    switch_running_mode  = true
  }
  workspace_access_properties {
    device_type_android    = "ALLOW"
    device_type_chromeos   = "ALLOW"
    device_type_ios        = "ALLOW"
    device_type_linux      = "DENY"
    device_type_osx        = "ALLOW"
    device_type_web        = "ALLOW"
    device_type_windows    = "ALLOW"
    device_type_zeroclient = "DENY"
  }
  workspace_creation_properties {
    custom_security_group_id            = aws_security_group.workspaces.id
    default_ou                          = "OU=WorkSpaces,DC=corp,DC=example,DC=com"
    enable_internet_access              = true
    enable_maintenance_mode             = true
    user_enabled_as_local_administrator = false
  }
  tags = {
    Name        = "WorkSpaces-Directory"
    Environment = "Production"
  }
}
# Example WorkSpace
resource "aws_workspaces_workspace" "example" {
  depends_on   = [aws_workspaces_directory.main]
  directory_id = aws_directory_service_directory.ad_connector.id
  bundle_id    = "wsb-bh8rsxt14" # Standard bundle ID
  user_name    = "john.doe"
  workspace_properties {
    compute_type_name                         = "STANDARD"
    user_volume_size_gib                      = 50
    root_volume_size_gib                      = 80
    running_mode                              = "AUTO_STOP"
    running_mode_auto_stop_timeout_in_minutes = 60
  }
  tags = {
    Name        = "john.doe-workspace"
    Environment = "Production"
  }
}

