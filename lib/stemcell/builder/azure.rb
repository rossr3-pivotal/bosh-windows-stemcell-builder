require 'open-uri'

module Stemcell
  class Builder
    class Azure < Base
      def build
        image_path = run_packer
        sha = Digest::SHA1.file(image_path).hexdigest
        manifest = Manifest::Azure.new('bosh-azure-stemcell-name', @version, sha, @os).dump
        super(iaas: 'azure', is_light: false, image_path: image_path, manifest: manifest)
      end

      private
        def packer_config
          Packer::Config::Azure.new().dump
        end

        def parse_packer_output(packer_output)
          disk_uri = nil
          packer_output.each_line do |line|
            puts line
            disk_uri ||= parse_disk_uri(line)
          end
          download_disk(disk_uri)
          Packager.package_image(image_path: File.join(@output_directory, 'root.vhd'), archive: true, output_directory: @output_directory)
        end

        def parse_disk_uri(line)
          unless line.include?("azure-arm,artifact,0") and line.include?("OSDiskUriReadOnlySas:")
            return
          end
          (line.split '\n').select do |s|
            s.start_with?("OSDiskUriReadOnlySas: ")
          end.first.gsub("OSDiskUriReadOnlySas: ", "")
        end

        def download_disk(disk_uri)
          Downloader.download(disk_uri, File.join(@output_directory, 'root.vhd'))
        end
    end
  end
end
