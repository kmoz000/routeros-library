# @Details: Function to Collect Wifi Interfaces informations.
# @Return:  []{ 
#       if-> wireless.name, 
#       ssid-> wireless.ssid,
#       type-> wireless.interface-type, 
#       key-> wireless.security-profiles(wireless.*id).wpa2-pre-shared-key,
#       keytypes-> wireless.security-profiles(wireless.*id).authentication-types
#   }


# @Details: Function to convert print value-list into stringtify json 
:global arrayToJSON do={
  :local myarray {astring="hello"; anumber=1, alist=("one", "two"), amix=({one="test", two=0}, "")};

}
:local myarray {kimo="hello"; like="me"};
:local json_string "{";
:foreach key in=[:toarray [:tostr [:parse [/system identity get name]]]] do={
  :local value $myarray->$key;
  :set json_string ($json_string . "\"" . $key . "\":\"" . $value . "\", ");
}
:if ([:len $json_string] > 1) do={
  :set json_string [:pick $json_string 0 ([:len $json_string] - 2)]; # Remove the trailing comma and space
}
:set json_string ($json_string . "}");
:put $json_string;



:do {
    :if ([:len [/interface wireless security-profiles find ]]>0) do={
        :set hasWirelessConfigurationMenu 1;
    }
} on-error={
    # no wireless
}
  if ($hasWirelessConfigurationMenu = 1) do={

    :put "has wireless configuration menu";

    :foreach wIfaceId in=[/interface wireless find] do={

      :local wIfName ([/interface wireless get $wIfaceId name]);
      :local wIfSsid ([/interface wireless get $wIfaceId ssid]);
      :local wIfSecurityProfile ([/interface wireless get $wIfaceId security-profile]);

      :local wIfKey "";
      :local wIfKeyTypeString "";

      :do {
        :set wIfKey ([/interface wireless security-profiles get [/interface wireless security-profiles find name=$wIfSecurityProfile] wpa2-pre-shared-key]);
        :local wIfKeyType ([/interface wireless security-profiles get [/interface wireless security-profiles find name=$wIfSecurityProfile] authentication-types]);

        # convert the array $wIfKeyType to the space delimited string $wIfKeyTypeString
        :foreach kt in=$wIfKeyType do={
          :set wIfKeyTypeString ($wIfKeyTypeString . $kt . " ");
        }

      } on-error={
        # no settings in security profile or profile does not exist
      }

      # remove the last space if it exists
      if ([:len $wIfKeyTypeString] > 0) do={
        :set wIfKeyTypeString [:pick $wIfKeyTypeString 0 ([:len $wIfKeyTypeString] -1)];
      }

      # if the wpa2 key is empty, get the wpa key
      if ([:len $wIfKey] = 0) do={
        :do {
          :set wIfKey ([/interface wireless security-profiles get [/interface wireless security-profiles find name=$wIfSecurityProfile] wpa-pre-shared-key]);
        } on-error={
          # no security profile found
        }
      }

      :local newWapIf;

      if ($wapCount = 0) do={
        # first wifi interface
        :set newWapIf "{\"if\":\"$wIfName\",\"ssid\":\"$wIfSsid\",\"key\":\"$wIfKey\",\"keytypes\":\"$wIfKeyTypeString\"}";
      } else={
        # not first wifi interface
        :set newWapIf ",{\"if\":\"$wIfName\",\"ssid\":\"$wIfSsid\",\"key\":\"$wIfKey\",\"keytypes\":\"$wIfKeyTypeString\"}";
      }

      :set wapCount ($wapCount + 1);

      :set wapArray ($wapArray.$newWapIf);
      
    }
  }