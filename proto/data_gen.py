"""
data_gen.py

Description: 

Donald MacIntyre - djm4912
"""

import math

def main() :

    filename = 'voltage_data_file.txt'
    f = open(filename, 'w')

    analog_v_data = []
    digital_v_data = []
    v_amp = int(input('Enter Voltage Amplitude (RMS): '))
    frequency = int(input('Enter sampling frequency: '))
    numDataPoints = int(input('Enter number of data points: '))
    time = 0
    step = 1/frequency
    for i in range(numDataPoints):
        time = step * i
        analog_v_data.append(math.sqrt(2)*v_amp * math.cos(time * 60 * 2))
        

    for i in analog_v_data:
        print(i)
        digital_v_data.append(((i+200)/400) * 1023)

    for i in digital_v_data:
        f.write(str(int(i)))
        f.write('\n')
    f.close()
    
if __name__ == "__main__":
    main()
