from firebase import firebase
import numpy as np
from matplotlib import pyplot as plt

fb_app = firebase.FirebaseApplication('https://arduinoble-ios-default-rtdb.asia-southeast1.firebasedatabase.app', None)
result = fb_app.get('/patient1/data/2022-03-26', None)

list = []
# get key-value pairs from results
for key, value in result.items():
    list.append(value)

list = np.array(list)
print(list.shape)

# plot the data
for j in range(list.shape[1]):
    plt.plot(list[:, j], label=str(j))
plt.legend()
plt.show()
