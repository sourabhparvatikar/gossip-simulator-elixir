Steps to run:

    Run the following command:
            mix run gossip.ex <number of nodes> <topology> <algorithm>

            where,
            <topology> : line or full or impLine or random2D or 3D or torus
            <algorithm>: gossip or push-sum


Working:

    1. In our program, Gossip and Push-sum algorithms run for line, imperfect line, 3D, Random 2D, Torus and full topologies.

    2. Algorithm:

      * Build topology.
        if line -> 
          assign the left and right nodes as neighbours for each node. First and last nodes will have only right and left neighbours respectively.
        if imperfect line -> 
          Same as line with an addition of randomly chosen node as an extra neighbour.
        if 3D ->
          Calculate the co-ordinates for each node in 3D plane. For a node (x1,y1,z1) if abs(x2-x1)+abs(y2-y1)+abs(z2-z1) == 1, then (x2,y2,z2) is a neighbour.
        if Random2D -> 
          Assign random coordinates to every node on a [0-1.0]X[0-1.0] square. A node y is a neighbour of node x if distance between x and y is less than 0.1.
        if full ->
          For every node p, all other nodes are it's neighbours.
        if torus ->
          If a node x is an edge node, neighbours are node next to it, node below or above it and opposite edge node.
      
      * start algorithm
        if gossip ->
          From the list of neighbours received from build topology algo, a node passes the rumour to randomly chosedn neighbour. When a node receives the rumour for the 10th time, it stops transmitting. 
          When all nodes stop passing, algorithm converges.
          Difference between start time and end time is convergence time.

        if push-sum ->
          From the list of neighbours received from build topology algo, a node is assigned s and w.
          Initially a random node sends half of its values to one of its neighbours.          
          When a node receives a message, it adds recived s and w to its own s and w. 
          if the difference in s/w does not change by more than 10^-10 for 3 consecutive times, it terminates.
      
      
Largest network for each topology and algorithm:

  -------------------------------------------------------------
  Algorithm | Full | 3D  | Random 2D | Torus | Imp line | line |
  -------------------------------------------------------------
  Gossip    | 10000|10000| 10000     | 7500  | 7500     | 5000 |
  -------------------------------------------------------------
  Push-sum  | 5000 | 5000| 5000      | 4000  | 4000     | 2000 |
  -------------------------------------------------------------


         
               
