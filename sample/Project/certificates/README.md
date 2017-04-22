Generate keystore like this

    keytool -genkey -v -keystore key.keystore -alias alias_name -keyalg RSA -keysize 2048 -validity 10000

Generate windows store certificate

    MakeCert.exe -r -h 0 -n "CN=<publisher_name>" -eku 1.3.6.1.5.5.7.3.3 -pe -sv my.pvk my.cer
    pvk2pfx.exe -pvk my.pvk -spc my.cer -pfx my.pfx