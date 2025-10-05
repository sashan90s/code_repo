import streamlit as st

# pages = {
#     "SihanLineages": [
#         st.Page("tableSearch.py", title="Table Graphs"),
#         st.Page("trigger_lineage.py", title="Trigger Graphs"),
#     ],
#     "Resources": [
#         st.Page("tableSearch.py", title="Table Graphs"),
#         st.Page("trigger_lineage.py", title="Trigger Graphs"),
#     ]
# }

pg = st.navigation([
    st.Page("tableSearch.py", title="Table Graphs", icon="🔥"),
    st.Page("trigger_lineage.py", title="Trigger Graphs", icon=":material/favorite:"),
])
pg.run()

