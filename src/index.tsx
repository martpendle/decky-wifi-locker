import {
  ButtonItem,
  PanelSection,
  PanelSectionRow,
  staticClasses,
  Field
} from "@decky/ui";
import {
  callable,
  definePlugin,
  toaster
} from "@decky/api"
import { useState, useEffect } from "react";
import { FaWifi, FaLock, FaLockOpen } from "react-icons/fa";

// Define callable functions for WiFi locking operations
const lockWifi = callable<[], any>("lock_wifi");
const unlockWifi = callable<[], any>("unlock_wifi");
const getWifiStatus = callable<[], any>("get_wifi_status");

function Content() {
  const [wifiStatus, setWifiStatus] = useState<{
    locked: boolean;
    ssid: string | null;
    bssid: string | null;
  }>({ locked: false, ssid: null, bssid: null });
  const [isLoading, setIsLoading] = useState<boolean>(false);

  // Function to refresh the WiFi status
  const refreshWifiStatus = async () => {
    try {
      const status = await getWifiStatus();
      setWifiStatus(status);
    } catch (error) {
      console.error("Error getting WiFi status:", error);
      toaster.toast({
        title: "Error",
        body: "Failed to get WiFi status",
        icon: <FaWifi />,
        critical: true
      });
    }
  };

  // Load WiFi status on component mount
  useEffect(() => {
    refreshWifiStatus();
  }, []);

  // Handle WiFi locking
  const handleLockWifi = async () => {
    setIsLoading(true);
    try {
      const result = await lockWifi();
      if (result.success) {
        toaster.toast({
          title: "WiFi Locked",
          body: `Locked to ${result.ssid}`,
          icon: <FaLock />
        });
        await refreshWifiStatus();
      } else {
        console.error("Lock error details:", result);
        
        toaster.toast({
          title: "Error",
          body: result.message,
          icon: <FaWifi />,
          critical: true
        });
      }
    } catch (error) {
      console.error("Error locking WiFi:", error);
      toaster.toast({
        title: "Error",
        body: "Failed to lock WiFi",
        icon: <FaWifi />,
        critical: true
      });
    } finally {
      setIsLoading(false);
    }
  };

  // Handle WiFi unlocking
  const handleUnlockWifi = async () => {
    setIsLoading(true);
    try {
      const result = await unlockWifi();
      if (result.success) {
        toaster.toast({
          title: "WiFi Unlocked",
          body: result.message,
          icon: <FaLockOpen />
        });
        await refreshWifiStatus();
      } else {
        console.error("Unlock error details:", result);
        
        toaster.toast({
          title: "Error",
          body: result.message,
          icon: <FaWifi />,
          critical: true
        });
      }
    } catch (error) {
      console.error("Error unlocking WiFi:", error);
      toaster.toast({
        title: "Error",
        body: "Failed to unlock WiFi",
        icon: <FaWifi />,
        critical: true
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <PanelSection title="WiFi Locker">
      {wifiStatus.locked ? (
        <>
          <PanelSectionRow>
            <Field
              label="Status"
              description={`Locked to ${wifiStatus.ssid || 'Unknown'}`}
              icon={<FaLock />}
            />
          </PanelSectionRow>
          <PanelSectionRow>
            <Field
              label="BSSID"
              description={wifiStatus.bssid || 'Unknown'}
              icon={<FaWifi />}
            />
          </PanelSectionRow>
          <PanelSectionRow>
            <ButtonItem
              layout="below"
              onClick={handleUnlockWifi}
              disabled={isLoading}
            >
              {isLoading ? "Unlocking..." : "Unlock WiFi"}
            </ButtonItem>
          </PanelSectionRow>
        </>
      ) : (
        <>
          <PanelSectionRow>
            <Field
              label="Status"
              description="WiFi is not locked"
              icon={<FaLockOpen />}
            />
          </PanelSectionRow>
          <PanelSectionRow>
            <ButtonItem
              layout="below"
              onClick={handleLockWifi}
              disabled={isLoading}
            >
              {isLoading ? "Locking..." : "Lock WiFi to Current AP"}
            </ButtonItem>
          </PanelSectionRow>
        </>
      )}
    </PanelSection>
  );
};

export default definePlugin(() => {
  console.log("WiFi Locker plugin initializing")

  return {
    // The name shown in various decky menus
    name: "WiFi Locker",
    // The element displayed at the top of your plugin's menu
    titleView: <div className={staticClasses.Title}>WiFi Locker</div>,
    // The content of your plugin's menu
    content: <Content />,
    // The icon displayed in the plugin list
    icon: <FaWifi />,
    // The function triggered when your plugin unloads
    onDismount() {
      console.log("WiFi Locker unloading")
    },
  };
});
