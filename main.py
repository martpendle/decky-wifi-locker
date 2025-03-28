import os
import json
import subprocess

# The decky plugin module is located at decky-loader/plugin
# For easy intellisense checkout the decky-loader code repo
# and add the `decky-loader/plugin/imports` path to `python.analysis.extraPaths` in `.vscode/settings.json`
import decky
import asyncio

class Plugin:
    # State to track if WiFi is currently locked
    wifi_locked = False
    current_ssid = None
    current_bssid = None
    
    # Path to the scripts
    lock_script_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), "backend", "lock_wifi.sh")
    unlock_script_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), "backend", "unlock_wifi.sh")
    
    # Lock WiFi to current BSSID
    async def lock_wifi(self) -> dict:
        if self.wifi_locked:
            return {"success": False, "message": "WiFi already locked", "ssid": self.current_ssid, "bssid": self.current_bssid}
        
        try:
            decky.logger.info("Locking WiFi to current BSSID")
            result = subprocess.run([self.lock_script_path], capture_output=True, text=True)
            
            if result.returncode == 0:
                # Parse the JSON output from the script
                output_data = json.loads(result.stdout.strip())
                self.current_ssid = output_data.get("ssid")
                self.current_bssid = output_data.get("bssid")
                self.wifi_locked = True
                
                decky.logger.info(f"WiFi locked to SSID: {self.current_ssid}, BSSID: {self.current_bssid}")
                return {
                    "success": True, 
                    "message": f"WiFi locked to {self.current_ssid}", 
                    "ssid": self.current_ssid, 
                    "bssid": self.current_bssid
                }
            else:
                decky.logger.error(f"Error locking WiFi: {result.stderr}")
                return {"success": False, "message": f"Error: {result.stderr}"}
        except Exception as e:
            decky.logger.error(f"Exception while locking WiFi: {str(e)}")
            return {"success": False, "message": f"Exception: {str(e)}"}
    
    # Unlock WiFi from BSSID lock
    async def unlock_wifi(self) -> dict:
        if not self.wifi_locked:
            return {"success": False, "message": "WiFi not locked"}
        
        try:
            decky.logger.info("Unlocking WiFi from BSSID lock")
            result = subprocess.run([self.unlock_script_path], capture_output=True, text=True)
            
            if result.returncode == 0:
                # Parse the JSON output from the script
                output_data = json.loads(result.stdout.strip())
                ssid = output_data.get("ssid")
                
                decky.logger.info(f"WiFi unlocked from SSID: {self.current_ssid}")
                self.wifi_locked = False
                prev_ssid = self.current_ssid
                self.current_ssid = None
                self.current_bssid = None
                
                return {"success": True, "message": f"WiFi unlocked from {prev_ssid}"}
            else:
                decky.logger.error(f"Error unlocking WiFi: {result.stderr}")
                return {"success": False, "message": f"Error: {result.stderr}"}
        except Exception as e:
            decky.logger.error(f"Exception while unlocking WiFi: {str(e)}")
            return {"success": False, "message": f"Exception: {str(e)}"}
    
    # Get the current WiFi lock status
    async def get_wifi_status(self) -> dict:
        return {
            "locked": self.wifi_locked,
            "ssid": self.current_ssid,
            "bssid": self.current_bssid
        }
    
    # Asyncio-compatible long-running code, executed in a task when the plugin is loaded
    async def _main(self):
        self.loop = asyncio.get_event_loop()
        decky.logger.info("WiFi Locker plugin initialized")

    # Function called first during the unload process, utilize this to handle your plugin being stopped
    async def _unload(self):
        # Ensure WiFi is unlocked when plugin is unloaded
        if self.wifi_locked:
            try:
                await self.unlock_wifi()
            except Exception as e:
                decky.logger.error(f"Error unlocking WiFi during unload: {str(e)}")
        decky.logger.info("WiFi Locker plugin unloaded")

    # Function called after `_unload` during uninstall, utilize this to clean up processes
    async def _uninstall(self):
        decky.logger.info("WiFi Locker plugin uninstalled")

    # Migrations that should be performed before entering `_main()`.
    async def _migration(self):
        decky.logger.info("Migrating WiFi Locker plugin")
        # Migrate logs
        decky.migrate_logs(os.path.join(decky.DECKY_USER_HOME,
                                        ".config", "decky-wifi-locker", "wifi-locker.log"))
        # Migrate settings
        decky.migrate_settings(
            os.path.join(decky.DECKY_HOME, "settings", "wifi-locker.json"),
            os.path.join(decky.DECKY_USER_HOME, ".config", "decky-wifi-locker"))
        # Migrate runtime data
        decky.migrate_runtime(
            os.path.join(decky.DECKY_HOME, "wifi-locker"),
            os.path.join(decky.DECKY_USER_HOME, ".local", "share", "decky-wifi-locker"))
