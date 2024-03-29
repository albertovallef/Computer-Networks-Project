from TestSim import TestSim

def main():
    # Get simulation ready to run.
    s = TestSim();

    # Before we do anything, lets simulate the network off.
    s.runTime(1);

    # Load the the layout of the network.
    s.loadTopo("long_line.topo");

    # Add a noise model to all of the motes.
    s.loadNoise("no_noise.txt");

    # Turn on all of the sensors.
    s.bootAll();

    # Add the main channels. These channels are declared in includes/channels.h
    s.addChannel(s.COMMAND_CHANNEL);
    s.addChannel(s.GENERAL_CHANNEL);
    s.addChannel(s.NEIGHBOR_CHANNEL); # Added channels to the simulation
    s.addChannel(s.FLOODING_CHANNEL);
    s.addChannel(s.ROUTING_CHANNEL);
    s.addChannel(s.TRANSPORT_CHANNEL);

    # After sending a ping, simulate a little to prevent collision.

    # ***IMPORTANT*** - change TABLE_SIZE according to the number of nodes when using routing
    s.runTime(100);
    s.testServer(1, 41);
    s.runTime(100);
    # s.testClient(5, 1,   3, 10 , 30);
    s.hello(5, "Bob", 3);
    s.runTime(100);
    s.hello(2, "Andi", 5);
    s.runTime(100);
    # s.hello(4, "Ale", 5);
    # s.runTime(100);
    s.hello(3, "John", 4);
    s.runTime(100);
    # s.listur(2);
    #s.Msg(2, "Hello World!"); 
    #s.runTime(300);
    #s.listur(2);
    s.whisper(2, "Bob", "Hi!")
    s.runTime(300);
 

if __name__ == '__main__':
    main()
