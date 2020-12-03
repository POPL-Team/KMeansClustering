from matplotlib import pyplot as plt
import pandas as pd

centroid_data = pd.read_csv('centroids.csv', delimiter=',')
data_points = pd.read_csv('lengthVsHeight.csv', delimiter = ',')

print(centroid_data)
print(data_points)

for i in range(0, len(centroid_data), 4):
    plt.scatter(data_points['length'], data_points['height_percentage'])
    
    #plt.scatter(centroid_data.loc[i: i + 3]['x'], centroid_data.loc[i: i + 3]['y'])
    plt.scatter(centroid_data['x'][i], centroid_data['y'][i], c = "red")
    plt.scatter(centroid_data['x'][i + 1], centroid_data['y'][i + 1], c = "orange")
    plt.scatter(centroid_data['x'][i + 2], centroid_data['y'][i + 2], c = "lime")
    plt.scatter(centroid_data['x'][i + 3], centroid_data['y'][i + 3], c = "cyan")
    
    plt.show(block = False)
    input()
    plt.clf()