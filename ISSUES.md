 # Issues

 - App unregisters from the SIP server when the app is closed.
 - The app does not receive calls when it is closed.
 - Mute and speaker buttons do not work.
 - No ringing sound for incoming or outgoing calls.
 - User interface requires improvements.
 - Registration workflow needs updates:
	 - User "Srujan" should automatically register to ws://192.168.0.101:8088 with default credentials username: `1001` and password: `1234`.
	 - User "Nikhitha" should automatically register to ws://192.168.1.4:8088 with default credentials username: `1001` and password: `1234`.
	 - Users must be able to change these settings later.
	 - If the user logs in with only a username and password (for example, username `srujan`, password `12345`), their account configuration should be set automatically.
	 - Registration should be attempted automatically and retried at intervals if it fails.
 - Make the dialpad the default screen after the first successful login so the login page only appears once.

