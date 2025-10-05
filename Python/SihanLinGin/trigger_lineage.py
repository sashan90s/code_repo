import streamlit as st
import yaml
from pyvis.network import Network
from layout import app_layout


def content():
    st.markdown("this is a trigger graph page coming soon")

app_layout(content())