require 'securerandom'

module Packer
  module Config
    class Gcp < Base
      def initialize(account_json, project_id, source_image)
        @account_json = account_json
        @project_id = project_id
        @source_image = source_image
      end

      def builders
        [
          {
            'type' => 'googlecompute',
            'account_file' => @account_json,
            'project_id' => @project_id,
            'tags' => ['winrm'],
            'source_image' => @source_image,
            'image_family' => 'windows-2012-r2',
            'zone' => 'us-east1-c',
            'disk_size' => 50,
            'image_name' =>  "packer-#{Time.now.to_i}",
            'machine_type' => 'n1-standard-4',
            'omit_external_ip' => false,
            'communicator' => 'winrm',
            'winrm_username' => 'winrmuser',
            'winrm_use_ssl' => false,
            'metadata' => {
              'sysprep-specialize-script-url' => 'https://raw.githubusercontent.com/cloudfoundry-incubator/bosh-windows-stemcell-builder/master/scripts/setup-winrm.ps1'
            }
          }
        ]
      end

      def provisioners
        [
          Provisioners::INCREASE_WINRM_LIMITS,
          Provisioners::CREATE_PROVISION_DIR,
          Provisioners::UPLOAD_BOSH_PSMODULES,
          Provisioners::INSTALL_BOSH_PSMODULES,
          Provisioners::UPLOAD_AGENT,
          Provisioners::INSTALL_CF_FEATURES,
          Provisioners.install_agent("gcp"),
          Provisioners::CLEANUP_WINDOWS_FEATURES,
          Provisioners::DISABLE_SERVICES,
          Provisioners::SET_FIREWALL,
          Provisioners::CLEANUP_ARTIFACTS
        ]
      end
    end
  end
end
