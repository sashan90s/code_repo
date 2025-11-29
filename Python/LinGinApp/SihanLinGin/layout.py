# layout.py
import streamlit as st

def app_layout(content_fn):
    st.set_page_config(page_title="My App", layout="wide")
    st.title("SHNLineageView")
    st.markdown("this is the :blue[cool]est data lineage tool, built by Sihan and test by NHS Dorset Data Engineering Team")

    # Content area — call the specific page logic
    content_fn()
    # a subheader
    # then logic
