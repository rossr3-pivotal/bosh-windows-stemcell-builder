# Creating a vCenter/vSphere Stemcell by Hand

## Introduction

In order to create a vSphere stemcell by hand, you must first begin with an ISO or other VM image
that you can begin with. This document describes using VMware Workstation, VMware Fusion, and
vCenter to install the BOSH dependencies and then create a `.tgz` file that can be uploaded
to your BOSH director and used with Cloud Foundry.

### Dependencies

You will need:

* [ovftool](https://www.vmware.com/support/developer/ovf/) (only required for Workstation and Fusion). Please make sure `ovftool` command is available from your command line.
  It is installed by default in `C:\Program Files\VMware\VMware OVF Tool`.
* [Windows ISO](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2012-r2) (evaluation. you can also use a custom base image)
* [Golang](https://golang.org/dl/) Latest 1.8.x compiler
* [Ruby](https://www.ruby-lang.org/en/downloads/) Latest 2.3.x version
* VMware Workstation, or VMware Fusion, or access to a vSphere account
* [git](https://git-scm.com/downloads)
* [tar.exe](https://greenhouse.ci.cf-app.com/teams/main/pipelines/tar/resources/s3-bucket) If on Windows
* [VMware Tools](https://packages.vmware.com/tools/esx/6.0latest/windows/x64/VMware-tools-10.0.9-3917699-x86_64.exe)

## Step 1: Create base VM for stemcell

NOTE: These are instructions for installing windows from a Windows installation disk ISO.
You may adapt the instructions if you are starting from some different Windows image. Make sure
that your image **has `Hardware Compatibility` set to version 9**, and that it has VMware tools
installed.

### For VMware Fusion:

1. File => New
1. Select Installation Method: Create a custom virtual machine
1. Choose Operating System: Microsoft Windows => Windows Server 2012
1. Choose a Virtual Disk: Create a new virtual disk (default settings are fine)
1. Finish: Select `Customize Settings` you'll be prompted to save the VM before continuing (any name will do)
  - Other => Compatibility => Select Hardware Compatibility 9
  - Removable Devices => CD/DVD => 
    - Select 'Connect CD/DVD Drive'
    - Select ISO disk image
    - Advanced Options => Bus type => SCSI (required for HW version 9)
  - System Settings => Processor & Memory => Increase if desired (the defaults are fine, but a little slow).
1. Start VM
1. Install VMware Tools
1. Restart the VM as required to finish the install

### For VMware Workstation:

- Install VMWare workstation (> version 12 Pro)
- Create a new Virtual Machine 
  - Custom Advanced
  - Select Worksation 9.x Compatibility
  - Select "I will install operating system later"
  - Select the Windows 2012 version
  - Choose a name
  - BIOS
  - Adjust the appropriate Number of cores and processors
  - Adjust the appropriate memory
  - Select the correct Network Type (NAT)
  - LSI logic SAS Contoller Type
  - SCSI Disk Type 
  - Create a new virtual Disk
  - Adjust the size (Default 60GB) and Store virtual disk as a single file
  - Before finishing, select Customize Hardware:
    - Select New CD/DVD
    - Select "Use ISO Image file" and browse for the correct ISO
- Power on the new VM and install Windows
  - Select server with GUI
  - Select custom installation
  - Follow along the installation process, and add select a password for Administrator user
- After the VM has started successfully, right-click the machine name in Workstation and Install VMware Tools
- Shut down the VM
- Remove the ISO file from the CD/DVD drive
  - Select the settings for the VM
  - CD/DVD Remove
  - Add CD/DVD Drive
  - Select "Use Physical drive" and Auto Detect
  - Unselect "Connect at power on"
  - Click Ok
- Start the new VM

### For vCenter:

- If you are using an ISO, upload it to your datastore (you may need to install a web plugin to upload through your browser)
  - Click vCenter -> Datastores
  - Select desired datastore, and desired directory
  - Click "Upload a file to datastore" (harddisk icon with green plus), and upload ISO.

Create a new virtual machine (if you are using an existing template, select the creation type `Deploy from template` and select a template):

- In `Select compatibility` ensure that you choose `ESXi 5.5 and later` 
- Select Windows as `Guest OS Family` and Microsoft Windows Server 2012 as `Guest OS version`
- In `Customize hardware`
    - Select `Datastore ISO File` under `New CD\DVD Drive`
    - Expand the menu and select `Connect At Power On`
    - Click `Browse` and select the ISO you uploaded to your datastore
- After creating VM, click Power On in the `Actions` tab for your VM, then install Windows:
  - Select server with GUI
  - Select custom installation
  - Follow along the installation process, and add select a password for Administrator user
- In the vCenter web client, "Install VMware Tools" in the VM `Summary` tab.

## Step 2: Build & Install BOSH PSModules

- Clone this repo on your host (NOT in the VM for your stemcell), and expand the bosh-agent submodule:

**NOTE**: On Windows you MUST clone straight into `C:\\`, or the git clone and submodule update will fail due to file path lengths.

```
git clone --recursive https://github.com/cloudfoundry-incubator/bosh-windows-stemcell-builder
cd bosh-windows-stemcell-builder
gem install bundler
bundle install
rake package:psmodules
```

- Transfer `build/bosh-psmodules.zip` to your Windows VM.
- Unzip the zip file and copy the `BOSH.*` folders to `C:\Program Files\WindowsPowerShell\Modules`

## Step 3: Build & Install BOSH Agent

- On your host, run `rake package:agent`
- Transfer `build/agent.zip` to your Windows VM.
- On your windows VM, start `powershell` and run `Install-Agent -IaaS vsphere -agentZipPath <PATH_TO_agent.zip>`

## Step 4: Install CloudFoundry Cell requirements

- On your windows VM, start `powershell` and run `Install-CFFeatures`
- Power off your VM

## Step 5: Export image to OVA format

If you are using VMware Fusion or Workstation, locate the directory that has your VM's `.vmx` file. This defaults to
the `Documents\\Virtual Machines\\VM-name\\VM-name.vmx` path in your user's home directory.
Otherwise simply right click on the VM to find its location.

Convert the vmx file into an OVA archive using `ovftool`:

```
ovftool <PATH_TO_VMX_FILE> image.ova
```

## Step 6: Convert OVA file to a BOSH Stemcell

example:
```
rake package:vsphere_ova[./build/image.ova,./build/stemcell,1035.00]
```
