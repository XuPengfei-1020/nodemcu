-- start server
print('>>>>> before load start_server:', node.heap())
dofile('start.lc')
print('<<<<<< after load start_server:', node.heap())