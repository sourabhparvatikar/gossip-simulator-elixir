defmodule Project2 do
  use GenServer

  def checkEtsTable(numNodes, startTime,table, parent) do
    
    [{_, currentCount}] = :ets.lookup(table, "count")

    if currentCount == (0.9*numNodes) do
      currentTime = System.system_time(:millisecond)
      endTime = currentTime - startTime
      IO.puts "Convergence Achieved in = "<> Integer.to_string(endTime)
      Process.exit(parent, :kill)
    end
    checkEtsTable(numNodes,startTime, table, parent)
  end

  def buildTopology(topology,allNodes) do
    case topology do
      "full" -> buildFull(allNodes)
      "line" -> buildLine(allNodes)
      "impLine" -> impBuildLine(allNodes)
      "random2D" -> random2DInitiator(allNodes)
      "3D" -> build3D(allNodes)
      "torus" -> buildTorus(allNodes)
    end
  end

  def buildFull(allNodes) do
    Enum.each(allNodes, fn(k) ->
      adjList=List.delete(allNodes,k) 
      updateAdjacentListState(k,adjList)
    end)
  end

  def buildLine(allNodes) do
    numNodes=Enum.count allNodes
    Enum.each(allNodes, fn(k) -> 
      index = Enum.find_index(allNodes, fn(x) -> x==k end)
      adjList = []

      adjList = adjList ++ 
      if index > 0 do
        neighbhour1 = Enum.fetch!(allNodes, index - 1)
        [neighbhour1]
      else
        []
      end

      adjList = adjList ++ 
      if index < numNodes - 1 do
        neighbhour2 = Enum.fetch!(allNodes, index + 1)
        [neighbhour2]
      else
        []
      end

      updateAdjacentListState(k,adjList)
    end)
  end

  def impBuildLine(allNodes) do
    numNodes=Enum.count allNodes
    Enum.each(allNodes, fn(k) -> 
      index = Enum.find_index(allNodes, fn(x) -> x==k end)
      adjList = []

      adjList = adjList ++ 
      if index > 0 do
        neighbour1 = Enum.fetch!(allNodes, index - 1)
        [neighbour1]
      else
        []
      end

      adjList = adjList ++ 
      if index < numNodes - 1 do
        neighbour2 = Enum.fetch!(allNodes, index + 1)
        [neighbour2]
      else
        []
      end

      tempNodes = List.delete(allNodes, k)
      tempNodes = tempNodes -- adjList
      neighbour3 = Enum.random(tempNodes)
      adjList = adjList ++ [neighbour3]

      updateAdjacentListState(k,adjList)
    end)
  end

  def random2DInitiator(allNodes) do
    tempCoList = []
    allCordinatesList = Enum.map(allNodes, fn k -> {:rand.uniform(),:rand.uniform()} end)
    Enum.each(allNodes, fn(k) ->  
      index=Enum.find_index(allNodes, fn(x) -> x==k end)
      cordinates = Enum.fetch!(allCordinatesList, index)
      tempCoList = List.delete_at(allCordinatesList, index)
      neighbourIndexes = findNeighbours(cordinates, tempCoList, allCordinatesList)
      adjList = Enum.map(neighbourIndexes, fn x -> Enum.fetch!(allNodes, x) end)
      updateAdjacentListState(k,adjList)
    end)
  end

  def findNeighbours(cordinates, tempCoList, allCordinatesList) do
    neighbourCordinates = Enum.filter(tempCoList, fn x -> :math.sqrt(:math.pow((elem(cordinates,0) - elem(x,0)),2) + :math.pow((elem(cordinates,1) - elem(x,1)),2)) < 0.1 end)
    neighbourIndexes = Enum.map(neighbourCordinates, fn x -> Enum.find_index(allCordinatesList, fn(y) -> y==x end) end)  
    neighbourIndexes
  end

  def build3D(allNodes) do
    numNodes=Enum.count allNodes
    cr=Float.floor(nth_root(3,numNodes))
    li=Enum.map(allNodes,fn(x)->getCoordinates(Enum.find_index(allNodes,fn k -> k == x end),cr) end)
    Enum.each(0..numNodes-1,fn(nn) ->
      adjList=getAdjacentNodes(nn,li)
      adjList=Enum.map(adjList,fn g -> Enum.at(allNodes,g) end)
      updateAdjacentListState(Enum.at(allNodes,nn),adjList)
    end)
  end

  def nth_root(n, x, precision \\ 1.0e-5) do
    f = fn(prev) -> ((n - 1) * prev + x / :math.pow(prev, (n-1))) / n end
    fixed_point(f, x, precision, f.(x))
  end

  def getCoordinates(x,cr) do
    node=x
    zC=div(node,trunc(cr*cr))
    point=rem(node,trunc(cr*cr))
    yC=div(point,trunc(cr))
    xC=rem(point,trunc(cr))
    {x,xC,yC,zC}
  end

  def getAdjacentNodes(x,li) do
    del=Enum.filter(li,fn c -> elem(c,0) == x end)
    List.delete(li,del)
    adj1=Enum.filter(li,fn(a)-> abs(elem(Enum.at(del,0),1)-elem(a,1))+abs(elem(Enum.at(del,0),2)-elem(a,2))+abs(elem(Enum.at(del,0),3)-elem(a,3)) == 1 end)
    adj=Enum.map(adj1,fn(y)->elem(y,0) end)
    adj
  end
  
  defp fixed_point(_, guess, tolerance, next) when abs(guess - next) < tolerance, do: next
  
  defp fixed_point(f, _, tolerance, next), do: fixed_point(f, next, tolerance, f.(next))

  def getNeighboursInTorus(magicNumber,actualN,x) do
    x=x+1
    neighbours=[]
    neighbours= neighbours ++
    if x-magicNumber > 0 do
      [x-magicNumber]
    else
      if rem(x,magicNumber) != 0 do
        [actualN - magicNumber + rem(x, magicNumber)]
      else
        [actualN]
      end
    end
    neighbours= neighbours ++
    if x + magicNumber <= actualN do
      [x+magicNumber]
    else
      if rem(x,magicNumber) != 0 do
        [rem(x, magicNumber)]
      else
        [magicNumber]
      end
    end
    neighbours= neighbours ++
    if rem(x,magicNumber) == 0 do
      [x-1,x+1-magicNumber]
    else
      if rem(x,magicNumber) == 1 do
        [x+1,x-1+magicNumber]
      else
        [x-1,x+1]
      end
    end
    neighbours
  end
  
  def buildTorus(allNodes) do
    numNodes=Enum.count allNodes
    magicNumber=:math.sqrt(numNodes)
    magicNumber=trunc(magicNumber)
    Enum.each(allNodes,fn(k)->
      adjList=getNeighboursInTorus(magicNumber,numNodes,Enum.find_index(allNodes,fn g -> g==k end))
      adjList=Enum.map(adjList,fn r -> Enum.at(allNodes,r-1) end)
      updateAdjacentListState(k,adjList)
    end)
  end

  def startAlgorithm(algorithm,allNodes, startTime) do
    case algorithm do
      "gossip" -> startGossip(allNodes, startTime)
      "push-sum" ->startPushSum(allNodes, startTime)
    end
  end

  def startGossip(allNodes, startTime) do
    chosenFirstNode = Enum.random(allNodes)
    updateCountState(chosenFirstNode, startTime, length(allNodes))
    recurseGossip(chosenFirstNode, startTime, length(allNodes))

  end

  def recurseGossip(chosenRandomNode, startTime, total) do
    
    myCount = getCountState(chosenRandomNode)
   
    cond do
      myCount < 11 ->
        adjacentList = getAdjacentList(chosenRandomNode)
        chosenRandomAdjacent=Enum.random(adjacentList)
        Task.start(Project2,:receiveMessage,[chosenRandomAdjacent, startTime, total])
        recurseGossip(chosenRandomNode, startTime, total)
      true -> 
        Process.exit(chosenRandomNode, :normal)
    end
      recurseGossip(chosenRandomNode, startTime, total)
  end

  def startPushSum(allNodes, startTime) do
    chosenFirstNode = Enum.random(allNodes)
    GenServer.cast(chosenFirstNode, {:ReceivePushSum,0,0,startTime, length(allNodes)})
  end
  
  def handle_cast({:ReceivePushSum,incomingS,incomingW,startTime, total_nodes},state) do

    {s,pscount,adjList,w} = state

    myS = s + incomingS
    myW = w + incomingW

    difference = abs((myS/myW) - (s/w))

    if(difference < :math.pow(10,-10) && pscount==2) do
      count = :ets.update_counter(:table, "count", {2,1})
      if count == total_nodes do
        endTime = System.monotonic_time(:millisecond) - startTime
        IO.puts "Convergence achieved in = " <> Integer.to_string(endTime) <>" Milliseconds"
        System.halt(1)
      end
    end

    pscount = pscount +
    if(difference < :math.pow(10,-10) && pscount<2) do
      1
    else
      0
    end
    pscount =
    if(difference > :math.pow(10,-10)) do
      0
    else
      pscount
    end

    state = {myS/2,pscount,adjList,myW/2}

    randomNode = Enum.random(adjList)
    sendPushSum(randomNode, myS/2, myW/2,startTime, total_nodes)
    {:noreply,state}
  end

  def sendPushSum(randomNode, myS, myW,startTime, total_nodes) do
    GenServer.cast(randomNode, {:ReceivePushSum,myS,myW,startTime, total_nodes})
  end

  def updatePIDState(pid,nodeID) do 
    GenServer.call(pid, {:UpdatePIDState,nodeID})
  end

  def handle_call({:UpdatePIDState,nodeID}, _from ,state) do 
    {a,b,c,d} = state
    state={nodeID,b,c,d}
    {:reply,a, state} 
  end

  def updateAdjacentListState(pid,map) do 
    GenServer.call(pid, {:UpdateAdjacentState,map})
  end

  def handle_call({:UpdateAdjacentState,map}, _from, state) do 
    {a,b,c,d}=state
    state={a,b,map,d}
    {:reply,a, state} 
  end 

  def updateCountState(pid, startTime, total) do 
      GenServer.call(pid, {:UpdateCountState,startTime, total}) 
  end

  def handle_call({:UpdateCountState,startTime, total}, _from,state) do 
    {a,b,c,d}=state
    if(b==0) do
      count = :ets.update_counter(:table, "count", {2,1})
      if(count == total) do
        endTime = System.monotonic_time(:millisecond) - startTime
        IO.puts "Convergence achieved in = #{endTime} Milliseconds"
        System.halt(1)
      end
    end
    state={a,b+1,c,d}
    {:reply, b+1, state} 
  end

  def getCountState(pid) do 
    GenServer.call(pid,{:GetCountState})
  end

  def handle_call({:GetCountState}, _from ,state) do 
    {a,b,c,d}=state
    {:reply,b, state} 
  end

  def receiveMessage(pid, startTime, total) do
    updateCountState(pid, startTime, total)
    recurseGossip(pid, startTime, total)
  end 

  def getAdjacentList(pid) do 
    GenServer.call(pid,{:GetAdjacentList})
  end

  def handle_call({:GetAdjacentList}, _from ,state) do 
    {a,b,c,d}=state
    {:reply,c, state} 
  end

  def init(:ok) do
    {:ok, {0,0,[],1}}
  end

  def start_node() do
    {:ok,pid}=GenServer.start_link(__MODULE__, :ok,[])
    pid
  end

  def infiniteLoop() do
    infiniteLoop()
  end

  def main() do
    arguments = System.argv()
    if (Enum.count(arguments) != 3) do
      IO.puts "Wrong Arguments Given"
      System.halt(1)
    end

    n=Enum.at(arguments, 0) |> String.to_integer()
    topology=Enum.at(arguments, 1)
    algorithm=Enum.at(arguments, 2)

    table = :ets.new(:table, [:named_table,:public])
    :ets.insert(table, {"count",0})

    allNodes = Enum.map((1..n), fn(x) ->
      pid=start_node()
      updatePIDState(pid, x)
      pid
    end)
  
    buildTopology(topology,allNodes)
    startTime = System.monotonic_time(:millisecond)
  
    startAlgorithm(algorithm, allNodes, startTime)
    infiniteLoop()
  end 
end

Project2.main()