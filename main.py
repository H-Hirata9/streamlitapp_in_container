import streamlit as st
import numpy as np
import pandas as pd

"# Hello. It's template app."
map_data = pd.DataFrame(
    np.random.randn(1000, 2) / [50, 50] + [35.6809, 139.7673],
    columns=['lat', 'lon'])

st.map(map_data)

