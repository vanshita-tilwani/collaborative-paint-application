# Collaborative Paint App - Team DLang Mafia
Collaborative Paint app is a multi-client application that allows multiple users to connect to a drawing canvas
and paint simulataneously. Clients can additional chat with each other

## Requirements
- dub
- Gtkd
- unit-threaded
- docker

## Installation
Installation depends on the setup of your development environment. We have built the app using **macOS**.

## How to run the app
Inside the FinalProject folder, there are 2 folders - draw_server and draw_client. Both are dub projects.
As the name suggests, "draw_server" contains the server code and "draw_client" consists of the client code.
The following are the steps to run the app.
-	Go inside "draw_server" folder and run "dub run --build=release".
-	Input the IP address and the port the server runs on.(Say, localhost and 50002)
-   Go inside "draw_client" folder and run "dub run --build=release".
-	Input the IP address and the port the client attempts to connect to.(Say, localhost and 50002)

You can see a canvas come up and use the features of the canvas. You can run multiple clients similarly.
Please look at the Milestone-10 video link to better understand the app features.

## Continuous Integration and Documentation

- You can find the documentation for the code in the /docs folder inside both the client and the server projects.
- Continuous Integration is set locally (due to limit on github). You can run it using "sudo ./act" from the root folder. (docker required)


## Application Features
-	The extra feature that we have included is the ability to chat with other clients.
-	4 sizes of brush strokes.
-	Color picker for choosing the brush strokes.


## Future Scope
-	Include the logic for erasing the canvas strokes.
-	Ability to add multiple shapes.
