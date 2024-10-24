# Pi-hole with Custom AdLists

This repository contains a script to set up Pi-hole with docker-compose and integrated adlists. 

## Quick Start

1. Clone the repository:
   ```
   git clone https://github.com/dakolli/pi-hole-with-adlists.git
   ```

2. Navigate to the cloned directory:
   ```
   cd pi-hole-with-adlists
   ```

3. Make the script executable:
   ```
   chmod +x pi-hole.sh
   ```

4. Run the script with sudo:
   ```
   sudo ./pi-hole.sh
   ```

5. After installation, access the Pi-hole admin interface:
   - Open a web browser and go to `http://localhost/admin`
   - Enter the password found in the `password.txt` file

Your Pi-hole with lists already imported should now be set up and running.

Run `chmod +x cleanup.sh` and `./cleanup.sh` to remove the container and reset the Pi-hole setup if you run into any issues
