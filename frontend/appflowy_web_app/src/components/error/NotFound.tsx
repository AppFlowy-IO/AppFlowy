import React from 'react';
import { Container, Box, Typography, Button } from '@mui/material';
import { Link } from 'react-router-dom';

const NotFound = () => {
  return (
    <Container component='main' maxWidth='xs'>
      <Box
        sx={{
          marginTop: 8,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          textAlign: 'center',
        }}
      >
        <Typography variant='h1' component='h1' color='error' gutterBottom>
          404
        </Typography>
        <Typography variant='h5' component='h2' gutterBottom>
          Page Not Found
        </Typography>
        <Typography variant='body1' color='textSecondary'>
          Sorry, the page you're looking for doesn't exist.
        </Typography>
        <Button component={Link} to='https://appflowy.io' variant='contained' color='primary' sx={{ mt: 3 }}>
          Go to AppFlowy.io
        </Button>
      </Box>
    </Container>
  );
};

export default NotFound;
