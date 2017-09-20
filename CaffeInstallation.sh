pip install protobuf
echo 'export CAFFE_ROOT=/opt/3D-Caffe' >> ~/.bashrc
echo 'export PYTHONPATH=/opt/3D-Caffe/distribute/python:$PYTHONPATH' >> ~/.bashrc
echo 'export PYTHONPATH=/opt/3D-Caffe/python:$PYTHONPATH' >> ~/.bashrc
echo 'export PATH=/usr/local/cuda-8.0/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/opt/3D-Caffe/distribute/lib:/usr/local/cuda-8.0/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
