import pandas as pd

# The provided timing report as a multi-line string (for this example)
timing_report = """
Startpoint: A (input port clocked by CLK)
Endpoint: Z (output port clocked by CLK)
Path Group: CLK
Path Type: max

Point                                          Trans       Incr       Path
-----------------------------------------------------------------------------
clock CLK (rise edge)                           0.00       0.00       0.00
clock network delay (ideal)                                0.00       0.00
input external delay                                       0.00       0.00 r
A (in)                                          1.00       0.00 &     0.00 r
U1/cp (BUFF)                                    1.00       0.00 &     0.00 r
U1/Y (BUFF)                                     1.00       1.00 &     1.00 r
UMUX/A (MUX)                                    1.00       0.00 &     1.00 r
UMUX/Y (MUX)                                    3.00       1.00 &     2.00 r
Z (out)                                         3.00       0.00 &     2.00 r
data arrival time                                                     2.00

clock CLK (rise edge)                           0.00      10.00      10.00
clock network delay (ideal)                                0.00      10.00
output external delay                                      0.00      10.00
data required time                                                   10.00
-----------------------------------------------------------------------------
data required time                                                   10.00
data arrival time                                                    -2.00
-----------------------------------------------------------------------------
slack (MET)                                                           8.00



Startpoint: B (input port clocked by CLK)
Endpoint: C (output port clocked by CLK)
Path Group: CLK
Path Type: max

Point                                          Trans       Incr       Path
-----------------------------------------------------------------------------
clock CLK (rise edge)                           0.00       0.00       0.00
clock network delay (ideal)                                0.00       0.00
input external delay                                       0.00       0.00 r
A (in)                                          1.00       0.00 &     0.00 r
U1/cp (BUFF)                                    1.00       0.00 &     0.00 r
U1/Y (BUFF)                                     1.00       1.00 &     1.00 r
UMUX/A (AUX)                                    1.00       0.00 &     1.00 r
UMUX/Y (MUX)                                    3.00       10.00 &     2.00 r
Z (out)                                         3.00       0.00 &     2.00 r
data arrival time                                                     2.00

clock CLK (rise edge)                           0.00      10.00      10.00
clock network delay (ideal)                                0.00      10.00
output external delay                                      0.00      10.00
data required time                                                   10.00
-----------------------------------------------------------------------------
data required time                                                   10.00
data arrival time                                                    -2.00
-----------------------------------------------------------------------------
slack (MET)                                                           8.00
"""

# Function to extract key information from the timing report
def parse_timing_report(report):
    lines = report.splitlines()
    
    timing_data_list = []  # To store data for each timing path
    startpoint = endpoint = path_group = path_type = ""
    data_arrival_time = data_required_time = slack = 0.0
    logic_level = 0
    highest_incr = 0.0  # To store the highest incremental delay
    count_logic = False  # Trigger for counting logic levels

    for line in lines:
        if "Startpoint:" in line:
            # Save data of the previous path before processing the new one
            if startpoint:
                timing_data_list.append({
                    "Startpoint": startpoint,
                    "Endpoint": endpoint,
                    "Path Group": path_group,
                    "Path Type": path_type,
                    "Level of Logic": logic_level,
                    "Data Arrival Time": data_arrival_time,
                    "Data Required Time": data_required_time,
                    "Slack": slack,
                    "Highest Incr (Launch Side)": highest_incr
                })
            # Reset for the new path
            startpoint = line.split(":")[1].strip().split()[0]
            endpoint = path_group = path_type = ""
            data_arrival_time = data_required_time = slack = 0.0
            logic_level = 0
            highest_incr = 0.0
            count_logic = False  # Reset counting trigger
        elif "Endpoint:" in line:
            endpoint = line.split(":")[1].strip().split()[0]
        elif "Path Group:" in line:
            path_group = line.split(":")[1].strip()
        elif "Path Type:" in line:
            path_type = line.split(":")[1].strip()
        elif "data arrival time" in line:
            data_arrival_time = float(line.split()[-1])
            count_logic = False  # Stop counting logic levels once we hit "data arrival time"
        elif "data required time" in line:
            data_required_time = float(line.split()[-1])
        elif "slack" in line:
            slack = float(line.split()[-1])
        elif "/cp" in line:
            count_logic = True  # Start counting logic levels when encountering /cp
        elif count_logic and ("BUFF" in line or "MUX" in line or "AUX" in line):
            logic_level += 1  # Count logic levels only if we are in counting mode
        elif "Incr" in line or "0.00" in line:  # Check for incremental delay lines
            parts = line.split()
            if len(parts) > 2 and parts[2].replace('.', '', 1).isdigit():  # Check if Incr value is valid
                incr_value = float(parts[2])
                if incr_value > highest_incr:
                    highest_incr = incr_value  # Update if current value is the highest
    
    # Append the last path data
    if startpoint:
        timing_data_list.append({
            "Startpoint": startpoint,
            "Endpoint": endpoint,
            "Path Group": path_group,
            "Path Type": path_type,
            "Level of Logic": logic_level,
            "Data Arrival Time": data_arrival_time,
            "Data Required Time": data_required_time,
            "Slack": slack,
            "Highest Incr (Launch Side)": highest_incr
        })
    
    return timing_data_list

# Parse the report and create a DataFrame
timing_data_list = parse_timing_report(timing_report)
df = pd.DataFrame(timing_data_list)

# Display the DataFrame
print(df)
