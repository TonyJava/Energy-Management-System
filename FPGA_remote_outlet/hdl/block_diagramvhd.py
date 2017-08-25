"""
block_diagramvhd.py

Description: Takes a vhdl file as input and outputs a block diagram of the
entity description.  A .eps file is outputted containing the component diagram
and this diagram can be inserted into a word document.  Currently the vhd file
must be in the same directory as this program. The .gps file is also outputted
to the same directory

Only std_logic and std_logic_vector is currently supported
std_logic_vectors must be defined as (n-1 downto 0) to display properly

Donald MacIntyre - djm4912
"""

#TODO

import turtle
import sys

#VHDL Diagram creator constants
COMPONENT_WIDTH = 75 #set component rectangular width
IO_LINE_LENGTH = 180
SLASH_LINE_LENGTH = 20

def drawIO(sigName, width) :
    turtle.width(1)
    turtle.pd()
    turtle.fd(IO_LINE_LENGTH)       # was 100
    turtle.bk(IO_LINE_LENGTH*.9)    # was 90
    #prevent signal names from becoming too long
    #turtle.write(sigName[:15])
    #use full sig names
    turtle.write(sigName)
    turtle.bk(IO_LINE_LENGTH*.1)    # was 10
    if width > 1 :
        turtle.fd(IO_LINE_LENGTH*.75)       # was 75
        turtle.rt(45)
        turtle.fd(SLASH_LINE_LENGTH//2)     #fixed value of slash
        turtle.bk(SLASH_LINE_LENGTH)        #fixed slash value    
        turtle.fd(SLASH_LINE_LENGTH//2)     #fixed slash value
        turtle.lt(45)
        turtle.bk(10)        # was 10
        turtle.pu()
        turtle.rt(90)
        turtle.fd(20)      
        turtle.lt(90)
        turtle.write(str(width))
        turtle.fd(10)
        turtle.bk(IO_LINE_LENGTH * .7)      # was 60
        turtle.lt(90)
        turtle.fd(20)      # was 20
        turtle.rt(90)
        turtle.bk(IO_LINE_LENGTH * .05)     # was 5
        turtle.pd()

# this function places turtle facing due east at the top corner
# of the component rectangle with the center of the rectangle in the
# center of the window
def alignTurtletoKnown(width, height) :
    turtle.pu()
    turtle.home()
    turtle.bk(width//2)
    turtle.lt(90)
    turtle.fd(height//2)
    turtle.rt(90)
    turtle.pd()
    
def drawSquare(width, height, componentName) :
    alignTurtletoKnown(width,height)
    for i in range (0,2) :
        turtle.fd(width)
        turtle.rt(90)
        turtle.fd(height)
        turtle.rt(90)
    turtle.write(componentName)
        
def drawBlockDiagram(lst, componentName) :
    # deternmine number of inputs, outputs and inouts
    inp = 0
    outp = 0
    for sig in lst :
        if sig[1].upper() == "IN" :
            inp += 1;
        else :
            outp += 1;
    largestType = max(inp, outp)
    height = 50 * (largestType+1)
    
    drawSquare(COMPONENT_WIDTH,height, componentName)
    turtle.rt(90)
    for sig in lst :
        turtle.pu()
        if sig[1].upper() == "IN" :
            turtle.fd(50)
            turtle.lt(90)
            turtle.bk(IO_LINE_LENGTH)
            drawIO(sig[0], sig[2])
            turtle.fd(IO_LINE_LENGTH)
            turtle.rt(90)
    alignTurtletoKnown(COMPONENT_WIDTH, height)
    turtle.fd(75)
    turtle.rt(90)
    for sig in lst :
        if sig[1] != "in" :
            turtle.fd(50)
            turtle.lt(90)
            drawIO(sig[0],sig[2])
            turtle.rt(90)
    turtle.pu()
    turtle.home()
    turtle.setup(25+COMPONENT_WIDTH+(IO_LINE_LENGTH*2),height + 50)

# entity will be parsed into list as follows
# [(name, in/out/inout/ width),(name2, in/out/inout/ width),...]    
def parseVHDFile(f) :
    l = []
    lst = []
    keepLine = False
    # find and save component name
    for line in f :
        if "ENTITY" == line.split(' ')[0].upper() :
            componentName = line.split(' ')[1]
            keepLine = True
        if "END" == line.split(' ')[0].upper() :
            keepLine = False
        if keepLine :
            l.append(line.strip())
    # l now is a list contaning an entity description line by line
    # need to check line 1 for first port decleration

    # first decleration is on same line as "Port("
    if len(l[1].split(' ')) > 2 :
        special_case = l[1].split()
        width = returnWidthofStdLogicVector(special_case[4])
        spec = (special_case[1], special_case[3],width)
        lst.append(spec)
    count = 0;
    for line in l :
        #ignore first 2 lines
        count += 1
        if count >= 3 and len(line.split()) > 1:
            port = line.split()
            if port[0][0:2] != "--" :       # dont try to process a comment line
                if (port[3].upper() == "STD_LOGIC;" or port[3].upper() == "STD_LOGIC") :
                    width = 1;
                else :
                    width = returnWidthofStdLogicVector(port[3])
                portDesp = (port[0],port[2],width)
                lst.append(portDesp)
                # determine width of vector
    return lst,componentName

#need to return the width of a standard logic vector
#string passed in is in form std_logic_vector(NUMBER
# need to return number + 1
def returnWidthofStdLogicVector(string) :
    try :
        return int(string[17:]) + 1
    except ValueError:
        return 1
    
def main() :
    if sys.version[0] == '3' :
        filename = input("Enter the filename: ")
    else :
        filename = raw_input("Enter the filename: ")
    turtle.speed(0)
    turtle.width(2)
    turtle.pu()
    turtle.ht()
    turtle.pd()
    f = open(filename)
    entityLst, compName = parseVHDFile(f)
    turtle.title(compName)
    drawBlockDiagram(entityLst, compName)
    f.close()
    
    #output component drawing to .eps file compatibale with word
    ts = turtle.getscreen()
    ts.getcanvas().postscript(file = compName + ".eps")
    r = input("Press to quit")
    
if __name__ == "__main__":
    main()
